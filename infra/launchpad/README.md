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
- An SSH keypair for bootstrap. To create a dedicated one:

  ```
  ssh-keygen -t ed25519 -f ~/.ssh/launchpad-bootstrap -C launchpad
  ```

## Bring up the box

1. Log in to AWS SSO:

   ```
   aws sso login --profile playground-ops
   ```

2. Paste the bootstrap **public** key into two places:
   `authorizedKeys` in `hosts/nixos/launchpad/default.nix`, and the
   `-var ssh_public_key` flag below. (Two copies today; fix when it annoys.)

3. Apply:

   ```
   tofu init
   tofu apply -var ssh_public_key="$(cat ~/.ssh/launchpad-bootstrap.pub)"
   ```

4. Note the `public_ip` output. Verify the stock AMI works:

   ```
   ssh -i ~/.ssh/launchpad-bootstrap -o IdentitiesOnly=yes root@<ip>
   ```

   If the instance was already up before the key existed, reboot it. The
   AMI injects the EC2 keypair for root at boot only.

5. Rebuild the box from this flake. Run from the repo root. The devShell
   provides `nixos-rebuild` (the Mac does not ship one). Evaluation happens
   on the Mac, the build happens on the box (no linux builder needed):

   ```
   NIX_SSHOPTS="-i $HOME/.ssh/launchpad-bootstrap -o IdentitiesOnly=yes" \
   nixos-rebuild switch --flake .#launchpad \
     --target-host root@<ip> --build-host root@<ip>
   ```

   The NIX_SSHOPTS ceremony is only needed until matt's daily key lands in
   the box config (done) and the ssh `Host launchpad` entry is active on
   the Mac. After that: `--target-host root@launchpad --build-host root@launchpad`.

6. Verify user access:

   ```
   ssh matt@<ip>
   ```

From then on, day-2 changes are edits to `hosts/nixos/launchpad/` plus the
same `nixos-rebuild` command.

## SSH access (Mac)

`hosts/darwin/home/ssh.nix` defines `Host launchpad` pointing at the EIP.
The 1Password agent serves matt's daily key for it. Until the Mac config is
applied, use `ssh matt@<ip>` directly — the agent path already works.

## Resize the box

```
tofu apply -var instance_type=m8g.xlarge
```

Tofu stops the instance, changes the type, and starts it again. The EIP
keeps the public IP stable across resizes.

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
