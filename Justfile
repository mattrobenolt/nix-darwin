[private]
default:
    @just --list

[doc("Rebuild and switch to the current flake config for this host")]
[group("nix")]
[script("sh")]
apply:
    case "$(uname)" in
      Darwin) sudo darwin-rebuild switch --flake . ;;
      *) sudo nixos-rebuild switch --flake . ;;
    esac

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

[doc("Update flake inputs. Groups: core ghostty hyprland neovim (omit for interactive picker)")]
[group("scripts")]
update *groups:
    @nu scripts/update.nu {{ groups }}
