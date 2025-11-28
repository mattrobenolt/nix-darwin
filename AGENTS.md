# AGENTS.md

This file provides guidance to AI coding assistants when working with code in this repository.

## Repository Overview

This is a declarative macOS system configuration using nix-darwin and home-manager. It manages system packages, GUI applications (via Homebrew), system settings, and user dotfiles in a unified, reproducible way.

## Essential Commands

### Apply Configuration Changes
```bash
# Build and activate system configuration (requires sudo)
sudo darwin-rebuild switch

# Build without activating (for testing)
darwin-rebuild build --flake .

# Check what would change without building
darwin-rebuild check --flake .
```

### Development Workflow
```bash
# Format all Nix files (uses treefmt)
./scripts/format.sh

# Lint Nix files (statix + deadnix)
./scripts/lint.sh

# Run all checks: format, lint, and build
./scripts/check.sh
```

## Configuration Architecture

### Flake Structure
- **`flake.nix`**: Entry point defining system configurations
  - `darwinConfigurations`: macOS system definitions
  - `nixosConfigurations`: Linux system definitions (templates only)
  - Integrates nix-darwin + home-manager

### System-Level Configuration
- **`common.nix`**: Shared packages and settings across all machines (macOS and Linux)
  - Core CLI tools and system-wide packages
  - Sets `nix.enable = false` for Determinate Nix compatibility on macOS
- **`hosts/darwin/*.nix`**: Host-specific configurations
  - Host-specific package sets
  - Homebrew integration for GUI apps and casks
  - macOS system defaults (dock, finder, trackpad, etc.)
  - Custom launchd daemons (if any)
  - Package overlays for fixing broken builds

### User-Level Configuration (home-manager)
- **`home.nix`**: Base home-manager entry point
  - Sets username and home directory
  - Imports `home-common.nix` and `hosts/darwin/home.nix`
- **`home-common.nix`**: Shared user config across all machines
  - Imports common program configs from `common/`
- **`hosts/darwin/home.nix`**: Darwin-specific user config
  - Imports modular program configs from `hosts/darwin/home/`
  - Platform-specific overrides (git signing, etc.)
- **`hosts/darwin/home/*.nix`**: Per-program configurations
  - Individual modules for each configured program
  - May include subdirectories for complex configs (e.g., neovim)

### Common Configuration Modules
- **`common/*.nix`**: Shared program configurations across all machines

## Key Architectural Patterns

### Three-Layer Configuration Model
1. **System layer** (`common.nix` + `hosts/darwin/*.nix`): System packages, services, macOS settings
2. **Home-manager layer** (`home.nix` → `home-common.nix` + `hosts/*/home.nix`): User environment and dotfiles
3. **Per-program modules** (`hosts/*/home/*.nix`): Fine-grained program-specific settings

### Platform Separation
- Darwin (macOS): Active configuration in `hosts/darwin/`
- NixOS (Linux): Template examples only in `hosts/nixos/`

### Package Management Strategy
- **Nix packages**: CLI tools and development utilities (via `environment.systemPackages` or home-manager)
- **Homebrew casks**: GUI applications that need macOS-specific integration
- **Homebrew brews**: Services and specialized tools not available or better maintained in Homebrew

### Custom System Services
Custom launchd daemons can be defined in host-specific configs using `launchd.daemons.*`. Check host config files for current services.

## Determinates Nix Considerations

This setup uses Determinate Nix installer, not the standard Nix installer:
- `nix.enable = false` in `common.nix` prevents conflicts
- System requires `/etc/nix-darwin` symlink pointing to `~/.config/nix-darwin`
- Uses flakes by default

## Making Configuration Changes

### Adding a New Package
- **CLI tool for all machines**: Add to `common.nix` → `environment.systemPackages`
- **CLI tool for specific host**: Add to `hosts/darwin/<hostname>.nix` → `environment.systemPackages`
- **GUI app**: Add to host's `homebrew.casks` section
- **User-specific tool**: Add via home-manager in relevant home config

### Adding a New Program Configuration
1. Create new module in `hosts/darwin/home/<program>.nix`
2. Import it in `hosts/darwin/home.nix`
3. Use home-manager options (see https://nix-community.github.io/home-manager/options.xhtml)

### Fixing Broken Packages
Use `nixpkgs.overlays` in host config to override package builds. See existing host configs for examples of overriding broken builds.

## Development Practices

Always format and lint before committing changes using `./scripts/check.sh`.
