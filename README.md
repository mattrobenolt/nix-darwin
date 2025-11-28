# Matt's nix-darwin Configuration

Declarative macOS system configuration using [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager).

## What's Configured

### System (nix-darwin)
- **macOS System Settings**: Dock, Finder, trackpad, keyboard preferences
- **System Packages**: Development tools and CLI utilities
- **Homebrew Integration**: GUI apps and special packages
- **DNS Management**: Local coredns with automatic enforcement
- **Security**: Touch ID for sudo, extended sudo timeout (24 hours)
- **Networking**: Hostname, DNS servers, search domains

### User (home-manager)
- Shell configuration (zsh)
- User dotfiles (gradually migrating)

## Bootstrap: Setting Up a New Mac

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

### 3. Create System Symlink

This allows `darwin-rebuild` to work without specifying the flake path:

```bash
sudo ln -s ~/.config/nix-darwin /etc/nix-darwin
```

### 4. Apply Configuration

```bash
darwin-rebuild switch --flake ~/.config/nix-darwin
```

Or simply (after the symlink is created):

```bash
darwin-rebuild switch
```

### 5. Change Default Shell to Zsh

```bash
chsh -s /run/current-system/sw/bin/zsh
```

Enter your password when prompted.

### 6. Restart Terminal

Quit and reopen your terminal for all changes to take effect.

---

## Daily Usage

### Making Changes

1. Edit configuration files:
   - `flake.nix` - System configuration
   - `home.nix` - User/home-manager configuration

2. Commit your changes:
   ```bash
   cd ~/.config/nix-darwin
   git add .
   git commit -m "Description of changes"
   git push
   ```

3. Apply changes:
   ```bash
   darwin-rebuild switch
   ```

### Common Commands

```bash
# Apply configuration changes
darwin-rebuild switch

# Build without activating (test first)
darwin-rebuild build

# Update flake inputs (update package versions)
nix flake update

# See what would change without applying
darwin-rebuild build --dry-run

# View changelog
darwin-rebuild changelog
```

### Adding Packages

**System packages** (available to all users):
Edit `flake.nix` and add to `environment.systemPackages`:
```nix
environment.systemPackages = with pkgs; [
  # ... existing packages
  neofetch  # Add your package here
];
```

**Homebrew packages**:
Edit `flake.nix` in the `homebrew` section:
```nix
homebrew.brews = [ "your-package" ];
homebrew.casks = [ "your-app" ];
```

### Updating System

```bash
# Update flake inputs (gets latest package versions)
nix flake update

# Apply updates
darwin-rebuild switch

# Commit the updated lockfile
git add flake.lock
git commit -m "Update flake inputs"
```

---

## Configuration Files

- **`flake.nix`** - Main nix-darwin configuration
  - System packages
  - macOS system defaults
  - Homebrew integration
  - Networking and DNS
  - Security settings

- **`home.nix`** - home-manager configuration
  - User-specific settings
  - Shell configuration
  - Dotfiles (gradually migrating here)

- **`flake.lock`** - Locked dependency versions (commit this!)

---

## Maintenance

### Garbage Collection

Free up disk space by removing old system generations:

```bash
# Remove old generations older than 30 days
nix-collect-garbage --delete-older-than 30d

# Remove all old generations (keep only current)
nix-collect-garbage -d
```

### Rollback

If something breaks, rollback to previous generation:

```bash
# List available generations
darwin-rebuild --list-generations

# Rollback to previous
darwin-rebuild --rollback

# Or switch to specific generation
darwin-rebuild switch --switch-generation 42
```

---

## Secrets Management

This repository is **public** by design - it only contains:
- Software preferences
- System settings
- Package lists

**Never commit**:
- SSH keys
- API tokens
- Passwords
- Private credentials

Use separate tools for secrets:
- 1Password
- `age`/`sops-nix`
- Encrypted external storage

---

## Troubleshooting

### DNS not being enforced

The DNS enforcement daemon runs hourly. To trigger it manually:

```bash
sudo launchctl kickstart -k system/org.nixos.enforce-dns
```

### Shell not finding nix commands

Source the nix daemon setup:

```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

This is already in `.zshrc` but may need to be re-sourced.

### Rebuild fails

Try building first to see errors:

```bash
darwin-rebuild build --show-trace
```

---

## Resources

- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/)
- [home-manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Determinate Nix](https://determinate.systems/nix)
