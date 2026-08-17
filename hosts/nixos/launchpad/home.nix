{
  pkgs,
  lib,
  inputs,
  ...
}:

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
  imports = [
    ../home.nix
    inputs.porthole.homeModules.porthole-remote
  ];

  home = {
    stateVersion = "26.05";

    # Matches users.users.matt.home: identical absolute paths to the Mac so
    # synced pi state (trust.json, sessions, skills) resolves correctly.
    homeDirectory = lib.mkForce "/Users/matt";

    packages = [
      piWrapper
      # Secrets get seeded from 1Password. (awscli2 comes from the shared
      # NixOS layer.)
      pkgs._1password-cli
    ];

    # qmd is pkgs.qmd everywhere: the mattware package now builds the
    # llama.cpp backend in at build time (the runtime can only build into a
    # read-only store dir). No wrappers, no runtime build tools.

    file = {
      # Canonical ignore set for the pi-agent syncthing folder. The folder is
      # created by syncthing itself on first share; this symlink pre-exists so
      # the ignores are in effect before the first pull. The Mac side symlinks
      # the same file from this repo checkout.
      ".pi/agent/.stignore".source = ./files/stignore-pi-agent;

      # ~/code share: repo-managed literal ignore list. Do NOT use
      # "#include .stignore-shared" here — the shared file only exists after
      # the first sync, and a missing include fails ignore parsing, which
      # blocks that sync (chicken-and-egg, learned the hard way).
      "code/.stignore".source = ./files/stignore-code;

      # Public half of the box's keypair (the private half is an agenix secret,
      # see default.nix).
      ".ssh/id_ed25519.pub".text =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII13XL4pqymylPqF41vFZP74+91X5O017M/Tu7Jb6MR3 matt@launchpad\n";
    };

    # 1Password service account token lives ONLY on disk (0600), never in the
    # nix store. Loaded per shell when present. See README "Secrets" — and
    # note systemd services do not get this; if one ever needs op, give the
    # unit an EnvironmentFile pointing at the same file.
    sessionVariablesExtra = ''
      if [ -r "$HOME/.config/op/service-account-token" ]; then
        export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$HOME/.config/op/service-account-token")"
      fi
    '';
  };

  programs = {
    # porthole client: xdg-open/$BROWSER/open route URLs to the daemon on
    # the Mac (hosts/darwin/home/porthole.nix) over the ssh RemoteForward.
    porthole = {
      enable = true;
      # The module's default package uses builtins.currentSystem, which
      # does not exist in pure (flake) eval (and would be the darwin
      # build anyway: `just remote-apply` evals on the Mac). Pin it.
      package = inputs.porthole.packages.aarch64-linux.porthole-remote;
    };

    # aws-login: headless SSO login flags (see infra/launchpad/README.md).
    # Usage: aws-login --profile <name>
    zsh.shellAliases = {
      aws-login = "aws sso login --use-device-code --no-browser";
    };

    git = {
      # The box signs with its own key, registered on GitHub as a signing key
      # (the shared config points at matt's Mac key, which does not exist here).
      signing = {
        # Private key path, not the pubkey: with no ssh agent on the box,
        # git/ssh-keygen signs with the file directly.
        key = lib.mkForce "/Users/matt/.ssh/id_ed25519";
        signByDefault = lib.mkForce true;
      };
    };
  };
}
