# launchpad

EC2 bring-up for the agent box. See `docs/ec2-agent-box.md` for the full plan.

Directional choices for this scaffolding:

- OpenTofu, not Terraform. HCL is identical. The devShell provides `tofu`.
- Local state first. `backend.tf` documents the S3 migration for later.
- Boot the official NixOS AMI (https://nixos.github.io/amis/), then
  `nixos-rebuild` the flake onto it. No nixos-anywhere, no disko.
- No tailscale yet. Port 22 stays open until that iteration lands.
- No IAM instance profile. No DLM snapshots yet. No budget alert yet.

Boundary rule: tofu owns everything outside the guest. NixOS owns everything
inside it.

## Prereqs

- `tofu` and `nixos-rebuild` (both in the devShell).
- `aws` CLI with SSO access to the playground account.
- matt's daily SSH key (`~/.ssh/id_ed25519`, served by the 1Password agent).
  This same key is the EC2 keypair: there is no separate bootstrap key, by
  design — one fewer secret, and the key that births the box is the key that
  daily-drives it.

## Bring up the box

1. Log in to AWS SSO:

   ```
   aws sso login --profile playground
   ```

2. Apply:

   ```
   tofu init
   tofu apply -var ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
   ```

3. Note the `public_ip` output. Verify the stock AMI works:

   ```
   ssh root@<ip>
   ```

   The AMI injects the EC2 keypair for root at boot only. If the instance
   was already running before the key existed, reboot it.

4. Rebuild the box from this flake. Run from the repo root. Evaluation
   happens on the Mac, the build happens on the box (no linux builder
   needed). With the ssh `Host launchpad` entry active on the Mac, this is:

   ```
   just remote-apply
   ```

   which wraps:

   ```
   nixos-rebuild switch --flake .#launchpad \
     --target-host root@<ip> --build-host root@<ip>
   ```

5. Verify user access:

   ```
   ssh matt@<ip>
   ```

From then on, day-2 changes are edits to `hosts/nixos/launchpad/` plus
`just remote-apply`.

## SSH access (Mac)

`hosts/darwin/home/ssh.nix` defines `Host launchpad` pointing at the EIP.
The 1Password agent serves matt's daily key for it.

## Resize the box

```
tofu apply -var instance_type=m8g.xlarge
```

Tofu stops the instance, changes the type, and starts it again. The EIP
keeps the public IP stable across resizes.

## Secrets: 1Password service account

The box reads secrets headlessly via a 1Password service account. The
token is a bearer credential: scoped, revocable, stored only on the box at
`~/.config/op/service-account-token` (0600), never in the nix store or git.
Shells load it as OP_SERVICE_ACCOUNT_TOKEN (see launchpad home.nix).

One-time setup (Mac):

1. Create a shared vault named `launchpad` (service accounts cannot read
   Personal/Private vaults). Put box-relevant items there.
2. Create the service account (token prints exactly once):

   ```
   op service-account create launchpad --vault launchpad:read_items
   ```

   If the Mac's op CLI is not signed in, `eval $(op signin)` first, or use
   the web UI: 1password.com > Developer Tools > Service Accounts.

3. Copy the token to the clipboard, then plant it on the box without it
   touching the Mac's disk:

   ```
   pbpaste | ssh matt@<ip> 'umask 077 && mkdir -p ~/.config/op && cat > ~/.config/op/service-account-token'
   ```

4. Verify from a fresh shell on the box:

   ```
   op whoami
   op item list --vault launchpad
   ```

Usage on the box: `op read op://launchpad/<item>/<field>`.

Rotation: create a new service account, plant the new token the same way,
delete the old one in 1Password. No other state depends on it.

## Secrets: agenix (box-consumed)

Secrets the box's NixOS config consumes live encrypted in `secrets/`.
Recipients (`secrets/secrets.nix`): matt's daily key (editing on the Mac)
and launchpad's SSH host key (decryption at activation, `/run/agenix/`).

Add or edit a secret from the devShell on the Mac:

```
agenix -e secrets/<name>.age        # editor flow; rules from secrets.nix
agenix -r                           # rekey everything after recipient changes
```

Then reference in the box config: `age.secrets.<name>.file =
../../secrets/<name>.age` and use `config.age.secrets.<name>.path`.

The host key is pinned: its private half is a `launchpad` vault item, so
the agenix recipient (and the box's SSH fingerprint) survives rebirths.

## Day-2 auth: AWS SSO on the box

The box holds no instance role; AWS access is matt's SSO creds, cached in
`~/.aws/sso/cache` on the box. `~/.aws/config` was rsynced once — if
profiles change on the Mac, re-rsync it.

When aws calls fail with "Token has expired and refresh failed":

1. On the box, run: `aws-login --profile playground` (alias for
   `aws sso login --use-device-code --no-browser`; pass any profile).
2. It prints a URL and a code. Open the URL in any browser and approve.
3. Done — one login covers every profile, because they all share
   `sso_session = planetscale`.

Why these flags: the default flow is PKCE with a localhost callback, which
cannot complete on a headless box. `--no-browser` alone still waits on that
callback. `--use-device-code` switches to the device-authorization flow,
which only needs a browser somewhere, not on the box.

The access token lives ~1h and the CLI auto-refreshes it until the corp
SSO session cap; then re-login. Failure mode for agents mid-run is a plain
expired-token error, recoverable by logging in and re-running.

## Later iterations

- Tailscale: box joins the tailnet as a tagged device; then delete the SG
  inbound-22 rule and switch `Host launchpad` to the tailnet hostname.
- (Decided against SSM Session Manager as the access path: session brokerage
  adds latency herdr would feel, and it needs an instance profile, which the
  posture doc reserves. Revisit only as break-glass.)
- S3 state backend: follow the comments in `backend.tf`.
- Secrets seeding via `op`, box SSH + signing keys, GitHub registration.
- Syncthing folder for `~/.pi` (scoped), bulk `~/code` re-clone.
- herdr server config, curate-memory systemd timer (delete the Mac's
  launchd job at the same time; exactly one curation writer).
- DLM snapshots, budget alert, `scripts/box-scale` wrapper.

## Teardown

```
tofu destroy
```

## Rebirth (destroy -> recreate)

Everything on the box is either reproducible from the flake or seeded from
1Password. The bootstrap contract, in order:

1. `tofu apply` (the EIP survives in state if you only `-replace` the
   instance; a full destroy recreates it).
2. Plant the service-account token (see Secrets). This is the ONLY
   irreplaceable manual secret step.
3. Run the bootstrap (once written — see docs/ec2-agent-box.md): reads the
   box SSH keypair and syncthing key/cert from the launchpad vault, runs
   `pnpm install`, done. Identity keys coming from the vault means no
   re-registering with GitHub and no syncthing re-pairing.
4. `aws-login --profile playground` — intentionally manual. The box holding
   no standing AWS power is the design, not a gap.

Open: the bootstrap script (step 3) does not exist yet — it lands with the
secrets iteration, once the vault items do.
