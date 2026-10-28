# AGENTS.md

Guidance for AI coding assistants that work in this repository.

## Repository Overview

Declarative system configuration for four hosts, all defined in one flake: a work Mac (nix-darwin) and three NixOS machines. The flake manages system packages, services, macOS settings, Homebrew GUI apps, and user dotfiles through home-manager. The launchpad EC2 host adds OpenTofu infra under `infra/` and agenix secrets under `secrets/`.

## Essential Commands

Run `just` recipes from the repo root. Do not call `darwin-rebuild` or `nixos-rebuild` directly. The recipes select the correct command for the current host.

```bash
just check    # build the current host config, no activation
just apply    # rebuild and switch
just fmt      # format all Nix files
just lint     # statix + deadnix
just fix      # auto-fix lint issues
just update   # bump flake inputs (interactive gum picker)
```

`just apply` prompts for sudo when activation needs it. For validation work, prefer `just check`.

`nix develop` provides the tooling: just, statix, deadnix, nixfmt, fd, gum, nushell, agenix, nixos-rebuild, tofu, awscli2. After the first apply, `just` is a system package on the Mac and a home package on the NixOS hosts.

### launchpad recipes (remote EC2 box)

```bash
just remote-check  [ref]  # build on the box itself; the closure never lands on the Mac
just remote-apply  [ref]  # switch the box; pass a committed ref to exclude uncommitted changes
just remote-up            # start the EC2 instance, wait for ssh
just remote-down          # stop the instance; EBS and config persist, the EIP keeps the IP
```

The recipes call `tofu` and `aws`. Both come from the devShell.

### desktop PC recipes (LAN box, no checkout needed)

```bash
just desktop-check  [ref]  # build on the box itself; the closure never lands on the Mac
just desktop-apply  [ref]  # switch the box; pass a committed ref to exclude uncommitted changes
```

The box is driven as `matt@nixos.local` (mDNS, published by avahi on the box).
Root ssh is disabled on the box; activation elevates with its passwordless
sudo. `nixos-rebuild` comes from the devShell. The box needs no checkout of
this repo — evaluation happens locally and the build runs on the box.

## Hosts

| Flake attr | Machine | Config |
|---|---|---|
| `darwinConfigurations."Matts-MacBook-Pro"` | work laptop, aarch64-darwin | `hosts/darwin/work.nix` |
| `nixosConfigurations.launchpad` | EC2 agent box, aarch64-linux, us-west-2 | `hosts/nixos/launchpad/` |
| `nixosConfigurations.orbstack` | OrbStack VM on the Mac, aarch64-linux | `hosts/nixos/orbstack/` |
| `nixosConfigurations.nixos` | desktop PC, x86_64-linux | `hosts/nixos/nixos/` |

## Configuration Architecture

### Layering

1. System layer: `common.nix` (shared packages and settings) plus each host's own config.
2. Home-manager layer: `home.nix` (Darwin entry) and `hosts/nixos/home.nix` (Linux-shared entry) both import `home-common.nix`.
3. Shared program modules: `common/*.nix`, imported by `home-common.nix`. Keep anything machine-specific in the host's home config.
4. Per-host modules: `hosts/darwin/home/` and `hosts/nixos/<host>/home/` (or `home.nix`).

### Directory Map

| Path | Contents |
|---|---|
| `common.nix` | Shared system packages and settings. Sets `nix.enable = false`. NixOS hosts override it. |
| `common/` | Shared home-manager program modules (neovim, zsh, ...). |
| `home.nix`, `home-common.nix` | Home-manager entry points. |
| `hosts/darwin/` | Mac: system config, Homebrew, launchd daemons (syncthing), z53 DNS. |
| `hosts/nixos/launchpad/` | EC2 box: syncthing, tailscale, z53, agenix identity restore. |
| `hosts/nixos/nixos/` | Desktop: pure terminal, no DE/WM. |
| `hosts/nixos/orbstack/` | OrbStack VM: symlinks agent state from the Mac via `/mnt/mac`. |
| `infra/launchpad/` | OpenTofu for the EC2 box. Boundary rule: tofu owns everything outside the guest. NixOS owns everything inside it. Bring-up runbook: `infra/launchpad/README.md`. |
| `secrets/` | agenix `.age` files plus `secrets.nix` recipient rules. |
| `scripts/` | `update.nu` behind `just update`. `launchpad-bootstrap` for box rebirths. |
| `docs/` | `ec2-agent-box.md`, the launchpad design doc. |

### Package Management Strategy

- Nix packages: CLI tools and development utilities.
- Homebrew casks (Mac only): GUI apps that need macOS integration. Defined in `hosts/darwin/work.nix`.
- Homebrew brews: services and tools that brew maintains better than nixpkgs.
- Per-host overlays live in `flake.nix`: `llm-agents.overlays.shared-nixpkgs` on all hosts, `mattware` on Linux. Read `flake.nix` for the exact set per host.
- Fix a broken package with `nixpkgs.overlays` in the host config. Read existing host configs for examples.

### Secrets (agenix)

- Edit a secret with `just secret <name>`, which runs agenix from `secrets/` and stages the result. A raw invocation must also run from `secrets/`: agenix looks for `secrets.nix` in the current directory or a parent, and it looks the file argument up verbatim, so `agenix -e secrets/<name>.age` from the repo root never resolves. The private key must be present locally.
- After you add a secret or change recipients, rekey with `cd secrets && agenix -r` and commit the updated `.age` files. A new `.age` file must be tracked by git: the flake is a git flake, so an untracked secret fails evaluation.
- Never commit plaintext secret material.
- Recipients: matt's daily key plus the launchpad host key. The launchpad key is pinned on purpose, because rebirths restore it. Do not rotate it casually, because everything rekeys.

### Determinate Nix

- The Mac uses the Determinate installer, so `common.nix` sets `nix.enable = false`. home-manager follows through `sharedModules`. NixOS hosts re-enable the Nix module.
- `/etc/nix-darwin` symlinks to this repo. A bare `darwin-rebuild` finds the flake through that symlink when `--flake` is absent.

## Making Changes

- CLI tool for all machines: add it to `common.nix` under `environment.systemPackages`. Add user-scoped tools to the shared home set in `hosts/nixos/home.nix`.
- CLI tool for one host: add it to that host's config.
- GUI app on the Mac: add a cask in `hosts/darwin/work.nix`.
- Shared program config: create `common/<program>.nix` and import it in `home-common.nix`.
- Host-specific program config: create `hosts/<platform>/<host>/home/<program>.nix` and import it in that host's home entry.

Home-manager options reference: https://nix-community.github.io/home-manager/options.xhtml

## Development Practices

Run `just fmt` and `just lint` before you commit. Prefer `just check` over `just apply` for validation work.

The repository is public domain under the Unlicense (`LICENSE`).

### Commits in this repo

This repository does not follow a strict "user must pre-stage changes" workflow.

If Matt asks you to commit here, inspect the working tree, determine the intended scope from the conversation and diff, and stage those files yourself when the scope is clear. Do not stop just because nothing is staged yet.

Only ask for clarification when the scope is genuinely ambiguous or there are unrelated changes you cannot safely separate.
