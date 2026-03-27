# nix configuration

Unified system configuration for all machines via [nix-darwin](https://github.com/LnL7/nix-darwin) and [NixOS](https://nixos.org), with shared home-manager config.

## Machines

| Host | Type | Arch |
|------|------|------|
| `Matts-MacBook-Pro` | macOS (nix-darwin) | aarch64-darwin |
| `nixos` | NixOS — OrbStack VM | aarch64-linux |

## Structure

```
common/          # shared home-manager modules (all machines)
hosts/
  darwin/        # macOS system config + home-manager
  nixos/
    orbstack/    # OrbStack VM system config + home-manager
```

## Updating

From the Mac:
```bash
darwin-update
```

From inside the OrbStack VM:
```bash
nixos-update
```

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

Quit and reopen your terminal for all changes to take effect.

---

## Bootstrap: New NixOS Machine

### 1. Clone and point nixos-rebuild at the flake

```bash
sudo nixos-rebuild switch --flake /path/to/nix-darwin#<hostname>
```

For the OrbStack VM, the Mac filesystem is mounted so no clone is needed:

```bash
sudo nixos-rebuild switch --flake /mnt/mac/Users/matt/.config/nix-darwin#nixos
```
