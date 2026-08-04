[private]
default:
    @just --list

[doc("Build the current host config without activating it")]
[group("nix")]
[macos]
check:
    darwin-rebuild build --flake .

[doc("Build the current host config without activating it")]
[group("nix")]
[linux]
check:
    nixos-rebuild build --flake .

[doc("Rebuild and switch to the current flake config for this host")]
[group("nix")]
[macos]
apply:
    sudo darwin-rebuild switch --flake .

[doc("Rebuild and switch to the current flake config for this host")]
[group("nix")]
[linux]
apply:
    sudo nixos-rebuild switch --flake .

[doc("Format all nix files")]
[group("nix")]
fmt:
    nix fmt -- --tree-root .

[doc("Check for linting issues")]
[group("nix")]
lint:
    statix check --ignore .direnv --ignore '**/hardware-configuration.nix' .
    fd --extension nix --exclude hardware-configuration.nix --exclude .direnv --exec-batch deadnix

[doc("Fix linting issues automatically")]
[group("nix")]
fix:
    statix fix --ignore .direnv --ignore '**/hardware-configuration.nix' .
    fd --extension nix --exclude hardware-configuration.nix --exclude .direnv --exec-batch deadnix --edit

[doc("Update flake inputs. Groups: core ghostty herdr hyprland neovim (omit for interactive picker)")]
[group("scripts")]
update *groups:
    @nu scripts/update.nu {{ groups }}
