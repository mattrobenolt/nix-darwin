# EC2 agent box — plan

Move the pi/agent workload off the laptop onto an always-on remote NixOS box.
The laptop becomes a thin client and occasional second seat, not a replica.

Status: scaffolding (2026-08-15). Design converged 2026-08-14, but treat
every decision below as directional, not binding.

Scaffolding landed with these deviations from the text below:

- Name: **launchpad**, not agentbox. (c9g.2xlarge at bring-up, aarch64.)
- OpenTofu (`tofu`), not terraform.
- Boot the official NixOS AMI (https://nixos.github.io/amis/) + `nixos-rebuild
  --target-host`; nixos-anywhere/disko dropped. No disk layout control for now.
- Local tofu state first; S3 backend documented but not enabled.
- Bring-up runbook that reflects reality lives in `infra/launchpad/README.md`.

2026-08-16: syncthing daemon + `pi-agent` share live (4.25GB); ~/code
share joined and pulling (tens of GB, hours). tailscaled installed;
awaiting corp-tailnet tagged-device key (Matt). Still pending: diskstation
ignore parity + junk sweep, identity pinning via 1Password, curation
cutover (one-writer).

## Decisions already made

- **Multiplexer: herdr.** Already pinned in the flake (v0.8.0) with the pi
  integration installed. `herdr --remote agentbox` from the laptop is a thin
  client over SSH. Agents keep running when the laptop disconnects or sleeps.
- **AWS SSO on the box: device-code flow.**
  `aws sso login --profile X --use-device-code --no-browser` prints a URL +
  code; approve in the laptop browser; token caches on the box.
  `--no-browser` alone does NOT work (PKCE waits on a localhost callback).
  `~/.aws/config` copies over verbatim.
- **GitHub/git: box gets its own keys.** New ed25519 key for SSH, registered
  on GitHub. New SSH signing key registered as a signing key. `op-ssh-sign`
  (1Password GUI) does not port headless. SSH agent forwarding from the laptop
  is a transitional crutch only, not the end state.
- **Internal access: tailscale.** The box joins the tailnet as a **tagged
  device** (auth key, ACL-scoped), not as matt's user node. Needs tailnet
  admin cooperation. Internal SSH hosts then work box-native, with the box's
  own key deployed to them.
- **Secrets seeding: 1Password CLI.** `op` works headless on Linux. Seed
  `auth.json` (8 provider keys), slack/notion tokens, and the bootstrap SSH
  keypair from 1Password at provision time. sops-nix/agenix is the possible
  long-term home, not required for v1.
- **State sync: Syncthing, scoped.** Matt already runs Syncthing over all of
  ~/code (years, no issues) because humans write one-keyboard-at-a-time.
  `~/.pi` has autonomous writers (agents, hourly curation), so scope it:
  - Sync: `memory/`, `settings.json`, `auth.json`, `trust.json`, working tree,
    `sessions/` (the box's curation writer reads Mac-side sessions — required),
    `git/` (live git dirs sync fine; ~/code has done it for years).
  - Ignore (revised 2026-08-16): `sessions-index/`, `.cache` (live sqlite,
    rebuilt per machine via qmd embed), `node_modules/`, `.direnv/` (Mac
    /nix/store symlinks), `.pi-subagents/` (runtime state), and
    `*.sync-conflict-*` (so conflict forks never get indexed by qmd).
  - Canonical ignore file: `hosts/nixos/launchpad/files/stignore-pi-agent`,
    symlinked into place on both sides. Box-side changes need a syncthing
    restart (nix store mtimes are epoch 0 — mtime detection never fires).
  - **Exactly one curation writer across all machines.** The hourly
    curate-memory timer lives on the box; the launchd job on the Mac gets
    deleted at cutover. No exceptions.
  - Accept occasional `.sync-conflict` files in `memory/` as clutter, not
    loss. Sweep periodically.
- **Shape: one resizeable box.** Not small-always-on + worker. Builds want to
  be where the agent and checkout are; a worker split reintroduces the
  two-homes state problem. Exception if ever needed: `nix.buildMachines` to a
  spot worker is clean for nix-shaped builds only.
- **Cost posture: measure first.** Start on-demand (c9g.2xlarge ≈ $250/mo or
  m-family equivalent for 4GB/vCPU), watch load during real compile weeks for
  a month, then pick: Compute Savings Plan (~33% off, floats across families),
  resize-at-phase-boundaries (`box-scale` script; stop/retype/start ≈ 1 min,
  herdr `resume_agents_on_restore` brings the session back), or Hetzner
  dedicated (~€65/mo for 16C Ryzen) if the workload turns out always-big.

## Repo layout

```
hosts/nixos/home.nix         # landed: shared NixOS home layer (home-common + linux pkgs)
hosts/nixos/launchpad/       # landed
  default.nix      # system: openssh, user, nix settings (tailscale/timer later)
  hardware.nix     # amazon-image module import, zram, fstrim
  home.nix         # home-manager: imports ../home.nix, near-empty
infra/launchpad/             # landed
  backend.tf       # S3 backend: documented, commented out (local state first)
  main.tf          # provider, data sources
  vpc.tf           # dedicated VPC: 1 public subnet, IGW, route table
  instance.tf      # aws_instance (official NixOS AMI) + key_pair + EIP + SG
  variables.tf     # instance_type, region, key material, nixos_release
  outputs.tf       # public IP, instance ID
  README.md        # bring-up runbook
scripts/
  box-scale        # tofu apply -var instance_type=$1 (planned)
  # deferred: iam.tf (no role by default anyway), backups.tf (DLM), budget.tf
```

### Boundary rule

Terraform owns everything outside the guest: VPC, SG, instance, EBS, IAM,
snapshots. NixOS owns everything inside it. The only secrets crossing the
boundary: a tailscale auth key (via user_data or first-login) and the
bootstrap SSH public key.

Target account: the `playground` AWS account (self-contained, no prod blast
radius). Region: us-west-2 (latency to LA; SSO region is irrelevant).
Arch: aarch64 (Graviton) is proven by the orbstack config; pick x86_64 only
if a corp tool needs it.

## Security posture

- Security group: egress-only. No inbound 22 after bootstrap; all access over
  tailscale. (Optionally keep 22 open to a home CIDR as break-glass.)
- The box holds prod-adjacent access 24/7 unattended. Tailnet ACLs should
  scope the tagged device to only what agents need.
- No instance role by default. AWS API access goes through matt's SSO creds
  (short-lived), which limits standing power on the box.

## Bootstrap runbook

Phase 1 — tofu:
1. ~~Create 1Password bootstrap SSH keypair~~ — dropped 2026-08-16: the EC2
   keypair is matt's daily key (already 1Password-backed). No second key.
   Tailscale auth key still TBD when that iteration lands.
2. ~~Create the S3 state bucket~~ — deferred; local state for now.
3. `tofu -chdir=infra/launchpad init && apply`. Note the public IP.

Phase 2 — NixOS:
1. `nixos-rebuild switch --flake .#launchpad --target-host root@<ip>
   --build-host root@<ip>` (boots the official NixOS AMI; no nixos-anywhere).
2. Verify tailscaled up and the node appears in the tailnet with its tag.
3. Verify `herdr --remote launchpad` attaches from the laptop.
4. Remove the SG inbound-22 rule.

Phase 3 — auth: (done 2026-08-16, except 5)
1. ~~Seed `auth.json`~~ — the pi-agent syncthing share covers it.
2. ~~Copy `~/.aws/config`~~ — rsynced one-time. SSO device-code login done;
   one login covers all profiles (shared `planetscale` sso_session).
3. ~~Box SSH key + signing key~~ — one ed25519 keypair, registered on
   GitHub as both authentication and signing key. `gh auth` done.
4. ~~gitconfig~~ — signing.key = the box's private key path (no agent
   headless); op-ssh-sign never applied (darwin-only module).
5. Deploy the box SSH key to internal hosts that agents touch. [waits on
   tailscale]

Home directory note: the box's home IS /Users/matt (not /home/matt), so
synced absolute paths (trust.json, qmd index.yml, session keys) are valid
as-is. Most of the old Phase 5.3 papercut list evaporated.

Phase 4 — state: (partially done 2026-08-16)
1. Bulk re-clone ~/code from origin URLs (script over the Mac's remotes);
   rsync unpushed/local-only repos (bench-results, adventofcode, etc.).
   [or: share ~/code via syncthing folder bjkky-xjf6r — pending]
2. ~~rsync `~/.pi/agent/memory/`~~ — syncthing `pi-agent` share covers it.
3. ~~Configure the Syncthing folder per the scoped rules above~~ — done;
   canonical ignore file in hosts/nixos/launchpad/files/.
4. ~~`pnpm install` in the agent repo; verify `pi` runs~~ — done. `pi` is a
   home-manager wrapper (no pi-profile on the box); install with
   `pnpm install --frozen-lockfile` (never mutate the synced lockfile).
5. ~~`qmd embed` on the box~~ — done; index built, search verified.
   (node-llama-cpp has no linux-aarch64 CPU prebuilt; it falls back to a
   packaged backend and works anyway. No GPU required.)

Phase 5 — cutover:
1. Add the curate-memory systemd timer on the box.
2. Delete the launchd `pi-memory-curate` job on the Mac. (One writer.)
3. Fix `/Users/matt` → `/home/matt` papercuts: `trust.json`, extension
   paths in `notify.ts`, `system-prompt*.ts`, slack/notion packages.
4. Daily-drive via `herdr --remote agentbox` for a week. Keep SSH agent
   forwarding available as the fallback.

Phase 6 — after a month of measurement:
1. Decide: Savings Plan, resize cadence, or Hetzner.
2. Review DLM snapshot retention; decide whether `memory/` also gets a
   private git remote.
3. Revisit tailnet ACL scope against what agents actually used.

## Open decisions (Matt)

- Tailnet ACL scope for the tagged device. (Security.)
- How much credential power sleeps on the box. (Security.)

Resolved at scaffolding (2026-08-15): playground account + us-west-2;
c9g.2xlarge at bring-up, resize down after measuring; aarch64 (Graviton);
name is launchpad.
