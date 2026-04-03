[default]
_default:
  @just --list

update *args:
  nu scripts/update.nu {{args}}

apply:
  #!/usr/bin/env sh
  case "$(uname)" in
    Darwin) sudo darwin-rebuild switch --flake . ;;
    *) sudo nixos-rebuild switch --flake . ;;
  esac

fmt:
  nix fmt -- --tree-root .

# Check for linting issues
lint:
  statix check --ignore .direnv '**/hardware-configuration.nix' .
  deadnix --exclude .direnv '**/hardware-configuration.nix' .

# Fix linting issues automatically
fix:
  statix fix --ignore .direnv '**/hardware-configuration.nix' .
  deadnix --edit --exclude .direnv '**/hardware-configuration.nix' .
