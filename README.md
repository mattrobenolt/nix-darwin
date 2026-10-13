# nix configuration

Unified system configuration for all machines via [nix-darwin](https://github.com/nix-darwin/nix-darwin) and [NixOS](https://nixos.org), with shared home-manager config.

## Machines

| Host | Type | Arch |
|------|------|------|
| `Matts-MacBook-Pro` | macOS (nix-darwin) — work laptop | aarch64-darwin |
| `launchpad` | NixOS — EC2 agent box, us-west-2 | aarch64-linux |
| `orbstack` | NixOS — OrbStack VM on the Mac | aarch64-linux |
| `nixos` | NixOS — desktop PC | x86_64-linux |

## Structure

```
common.nix        shared system packages + settings (all machines)
common/           shared home-manager modules (all machines)
home.nix          home-manager entry point (darwin)
home-common.nix   shared home-manager imports (all machines)
hosts/
  darwin/         work laptop: system config, homebrew, launchd (syncthing, coredns), z53 DNS
  nixos/
    launchpad/    EC2 agent box (syncthing, tailscale, z53)
    nixos/        desktop PC (Hyprland)
    orbstack/     OrbStack VM (agent state shared with the Mac)
infra/launchpad/   OpenTofu: EC2 networking + instance, bring-up runbook
secrets/          agenix-encrypted secrets + recipient rules
scripts/          flake input updater (just update), launchpad rebirth
docs/             launchpad design doc
Justfile          check / apply / fmt / lint / update, remote-* for launchpad
```

## Updating

Everything goes through the Justfile from the repo root — the recipes pick the right command for the current host:

```bash
just check    # build the config, no switch
just apply    # rebuild + switch
just update   # bump flake inputs (interactive picker)
```

`launchpad` is remote. Build it on the box itself, so the Linux closure never lands on the Mac:

```bash
just remote-check   # build (on the box)
just remote-apply   # switch
just remote-up      # start the EC2 instance
just remote-down    # stop it — disk and config persist, the IP stays
```

The remote recipes target the Elastic IP, which is the bootstrap and break-glass path. The box also sits on the tailnet.

Outside the repo, the zsh aliases `darwin-update` (Mac) and `nixos-update` (Linux hosts) do the same rebuild.

## launchpad

The pi/agent workload runs on an always-on EC2 box. The laptop is a thin client. Two rules hold the setup together:

- OpenTofu owns everything outside the guest. NixOS owns everything inside it.
- The box's identity (ssh host key, tailscale node identity) is agenix-pinned, so a rebuilt box rejoins the tailnet as the same node.

Bring-up runbook: `infra/launchpad/README.md`. Rebirth of an existing box: `scripts/launchpad-bootstrap` (run from the repo root, service-account token on stdin). Design history: `docs/ec2-agent-box.md`.

## OrbStack VM — shared config

The OrbStack VM mounts the Mac filesystem at `/mnt/mac`. Home-manager symlinks several paths from the Mac instead of managing them:

- `~/.pi` and `~/.cache/qmd` — shared pi agent config, memory, and search index
- `~/code`
- `~/.agents/skills`, plus selected `~/.claude/*` and `~/.codex/*` directories

Manage these on the Mac. The VM picks them up automatically.

## SSH agent

SSH keys live in 1Password.

**Mac:** every connection uses the 1Password agent socket (`~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`).

**Mac → desktop PC (`nixos.local`):** the Mac forwards its agent. On the PC, SSH picks the agent by session — `$WAYLAND_DISPLAY` set (Hyprland) means the local 1Password desktop agent (`~/.1password/agent.sock`), unset (headless or SSH) means the forwarded agent from the Mac.

**launchpad:** matt's daily 1Password key is the EC2 keypair. There is no separate bootstrap key, by design.

**OrbStack VM:** the agent forwards through OrbStack's native Mac integration.

---

## Bootstrap: new Mac

### 1. Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart your terminal after installation.

### 2. Clone this repo

```bash
git clone https://github.com/mattrobenolt/nix-darwin.git ~/.config/nix-darwin
sudo ln -s ~/.config/nix-darwin /etc/nix-darwin
```

The symlink lets a bare `darwin-rebuild` find the flake.

### 3. Apply

```bash
cd ~/.config/nix-darwin
nix run github:nix-darwin/nix-darwin -- switch --flake .#Matts-MacBook-Pro
```

### 4. Restart your terminal

From here on, `just apply` handles updates — `just` is part of the applied config.

---

## Bootstrap: OrbStack VM

No clone — the VM reads the Mac's flake directly. From inside the VM:

```bash
sudo nixos-rebuild switch --flake /mnt/mac/Users/matt/.config/nix-darwin#orbstack
```

## Bootstrap: desktop PC

```bash
git clone https://github.com/mattrobenolt/nix-darwin.git ~/.config/nixos
sudo nixos-rebuild switch --flake ~/.config/nixos#nixos
```

## Bootstrap: launchpad

Follow the bring-up runbook in `infra/launchpad/README.md` — OpenTofu brings up the official NixOS AMI, then `just remote-apply` installs this flake on it.

## License

[Unlicense](UNLICENSE) — public domain, no warranty.
