# Matt's Multi-Platform Nix Configuration

Declarative system configuration for macOS (via [nix-darwin](https://github.com/LnL7/nix-darwin)) and Linux (via [NixOS](https://nixos.org/)), with user environment management via [home-manager](https://github.com/nix-community/home-manager).

## Repository Structure

```
~/.config/nix-darwin/
├── flake.nix                    # Main flake file, defines all machines
├── common.nix                   # Shared config across all machines
├── home.nix                     # Shared home-manager config
├── hosts/
│   ├── darwin/                  # macOS-specific hosts
│   │   └── work.nix            # Work MacBook Pro
│   └── nixos/                   # Linux-specific hosts
│       └── example.nix         # NixOS template
└── README.md
```

## What's Configured

### Shared Config (common.nix)
- **Core CLI Tools**: git, neovim, bat, eza, ripgrep, fd, etc.
- **Shell Tools**: zsh, starship, atuin, direnv, fzf, zoxide
- **Development**: Go, Node.js, Python, Nix tooling
- **Utilities**: tmux, zellij, btop, htop, network tools

### macOS Specific (hosts/darwin/work.nix)
- **macOS System Settings**: Dock, Finder, trackpad, keyboard
- **Work Packages**: kubectl, terraform, argocd, cloud tools
- **Homebrew Integration**: GUI apps and macOS-specific tools
- **DNS Management**: Local coredns with automatic enforcement
- **Security**: Touch ID for sudo, 24-hour sudo timeout

### User Config (home-manager)
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

## Adding New Machines

### Adding a macOS Machine

1. Copy an existing host config:
   ```bash
   cp hosts/darwin/work.nix hosts/darwin/personal.nix
   ```

2. Edit the new config with machine-specific settings:
   - Change `networking.hostName` and `networking.computerName`
   - Adjust packages, Homebrew casks, system settings
   - Modify DNS/networking as needed

3. Add the new configuration to `flake.nix`:
   ```nix
   darwinConfigurations."Matts-Personal" = nix-darwin.lib.darwinSystem {
     modules = [
       ./common.nix
       ./hosts/darwin/personal.nix
       { system.configurationRevision = self.rev or self.dirtyRev or null; }
       home-manager.darwinModules.home-manager
       { home-manager.users.matt = import ./home.nix; }
     ];
   };
   ```

4. Apply on the new machine:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix-darwin#Matts-Personal
   ```

### Adding a NixOS Machine

1. Install NixOS and generate hardware config:
   ```bash
   nixos-generate-config --root /mnt
   # Copy /mnt/etc/nixos/hardware-configuration.nix to your repo
   ```

2. Create your host config:
   ```bash
   cp hosts/nixos/example.nix hosts/nixos/myserver.nix
   # Edit with your settings
   ```

3. Add to `flake.nix`:
   ```nix
   nixosConfigurations."myserver" = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [
       ./common.nix
       ./hosts/nixos/myserver.nix
       ./hosts/nixos/myserver-hardware.nix
       home-manager.nixosModules.home-manager
       { home-manager.users.matt = import ./home.nix; }
     ];
   };
   ```

4. Apply:
   ```bash
   sudo nixos-rebuild switch --flake ~/.config/nix-darwin#myserver
   ```

---

## Daily Usage

### Making Changes

1. Edit configuration files:
   - `flake.nix` - System configuration
   - `home.nix` - User/home-manager configuration
   - `common.nix` - Shared packages/settings
   - `hosts/darwin/work.nix` - Host-specific config

2. Format and check your changes:
   ```bash
   cd ~/.config/nix-darwin

   # Format all nix files
   ./scripts/format.sh

   # Lint and check for issues
   ./scripts/lint.sh

   # Run everything (format, lint, build)
   ./scripts/check.sh
   ```

3. Commit your changes:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```

4. Apply changes:
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
