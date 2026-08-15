{ pkgs, lib, ... }:

let
  # On the Mac, `pi` goes through pi-profile (default/work/personal). The
  # box has exactly one agent home, so pi here is the raw binary.
  piWrapper = pkgs.writeShellScriptBin "pi" ''
    set -euo pipefail

    PI_HOME="$HOME/.pi/agent"
    PI_BIN="$PI_HOME/node_modules/.bin/pi"

    if [ ! -x "$PI_BIN" ]; then
      echo "pi is not installed in $PI_HOME" >&2
      echo "Run: cd $PI_HOME && pnpm install" >&2
      exit 1
    fi

    exec "$PI_BIN" "$@"
  '';
in
{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix.
  imports = [ ../home.nix ];

  home.stateVersion = "26.05";

  home.packages = [ piWrapper ];

  # Canonical ignore set for the pi-agent syncthing folder. The folder is
  # created by syncthing itself on first share; this symlink pre-exists so
  # the ignores are in effect before the first pull. The Mac side symlinks
  # the same file from this repo checkout.
  home.file.".pi/agent/.stignore".source = ./files/stignore-pi-agent;

  programs.git = {
    # The shared config signs with matt's Mac key, which does not exist
    # here. The box gets its own signing key in the auth iteration.
    signing.signByDefault = lib.mkForce false;
  };
}
