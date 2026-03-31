# nix configuration

Unified system configuration for all machines via [nix-darwin](https://github.com/LnL7/nix-darwin) and [NixOS](https://nixos.org), with shared home-manager config.

## Machines

| Host | Type | Arch |
|------|------|------|
| `Matts-MacBook-Pro` | macOS (nix-darwin) | aarch64-darwin |
| `orbstack` | NixOS — OrbStack VM (aarch64-linux) | aarch64-linux |
| `nixos` | NixOS — Desktop PC | x86_64-linux |

## Structure

```
common/           # shared home-manager modules (all machines)
common.nix        # shared system packages + settings
home-common.nix   # shared home-manager imports (mac + orbstack)
hosts/
  darwin/         # macOS system config + home-manager
  nixos/
    orbstack/     # OrbStack VM system config + home-manager
    nixos/        # Desktop PC system config + home-manager
```

## Updating

**Mac:**
```bash
darwin-update
```

**OrbStack VM** (runs against Mac's flake via `/mnt/mac`):
```bash
nixos-update
```

**Desktop PC:**
```bash
nixos-update
```

## OrbStack VM — Shared Config

The OrbStack VM mounts the Mac filesystem at `/mnt/mac`. Home-manager uses this to symlink
several directories directly from the Mac rather than managing them independently:

- `~/.pi` → Mac's `~/.pi` (shared pi agent config, memory, sessions)
- `~/.cache/qmd` → Mac's `~/.cache/qmd` (shared semantic search index + models)
- `~/code` → Mac's `~/code`
- `~/.claude/*` → Mac's `~/.claude/*` (shared Claude config)

This means you only manage these on the Mac; the VM picks them up automatically.

## SSH Agent

SSH keys are stored in 1Password. Agent behavior depends on context:

**Mac → Desktop PC (SSH forwarding):**
The Mac forwards its 1Password SSH agent when connecting to `nixos.local`. On the PC,
the SSH config uses `$WAYLAND_DISPLAY` to decide which agent to use:
- `$WAYLAND_DISPLAY` set (GUI/Hyprland session) → 1Password desktop agent (`~/.1password/agent.sock`)
- `$WAYLAND_DISPLAY` unset (headless/SSH session) → forwarded agent from Mac via `$SSH_AUTH_SOCK`

**OrbStack VM:**
SSH agent is forwarded automatically via OrbStack's native Mac integration.

---

## Bootstrap: New Mac

### 1. Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart your terminal after installation.

### 2. Clone This Repository

```bash
git clone https://github.com/mattrobenolt/nix-darwin.git ~/.config/nix-darwin
cd ~/.config/nix-darwin
```

### 3. Apply Configuration

```bash
sudo darwin-rebuild switch --flake .#"Matts-MacBook-Pro"
```

### 4. Restart Terminal

Quit and reopen your terminal for all changes to take effect. After this, use the `darwin-update` alias for subsequent updates.

---

## Bootstrap: OrbStack VM

No clone needed — the VM accesses the Mac's copy of the flake directly:

```bash
sudo nixos-rebuild switch --flake /mnt/mac/Users/matt/.config/nix-darwin#orbstack
```

After this, use the `nixos-update` alias for subsequent updates.

---

## Bootstrap: Desktop PC

### 1. Clone the repository

```bash
git clone https://github.com/mattrobenolt/nix-darwin.git ~/.config/nixos
```

### 2. Apply configuration

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#nixos
```

After this, use the `nixos-update` alias for subsequent updates.
