{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # `pi` runs the raw binary from the single agent home at ~/.pi/agent.
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

  # Canonical key sources (same module every other host reads from).
  sshKeys = import ../../../common/ssh-keys.nix { inherit lib; };
in
{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix.
  imports = [
    ../home.nix
    # herdr — per-host, not in home-common: the nixos desktop runs no herdr.
    ../../../common/herdr.nix
    ../../../common/herdr-plugins.nix
    ../../../common/herdr-plugin-tab-smart-rename.nix
    inputs.porthole.homeModules.porthole-remote
  ];

  home = {
    stateVersion = "26.05";

    # Matches users.users.matt.home: identical absolute paths to the Mac so
    # synced pi state (trust.json, sessions, skills) resolves correctly.
    homeDirectory = lib.mkForce "/Users/matt";

    # Appended after the shared layer's ~/.local/bin.
    sessionPath = lib.mkAfter [ "$HOME/.ps-toolbox/bin" ];

    packages = [
      piWrapper
      # herdr (the binary; config and plugins come from common/herdr*.nix
      # imports above — per-host, not in the shared NixOS layer).
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      # Secrets get seeded from 1Password. (awscli2 comes from the shared
      # NixOS layer.)
      pkgs._1password-cli
      # TR-100 machine report (login banner, matt.loginBanner below); also
      # on PATH for direct runs.
      inputs.usgc-machine-report.packages.${pkgs.stdenv.hostPlatform.system}.usgc-machine-report
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
      # see default.nix). Canonical source: common/ssh-keys.nix.
      ".ssh/id_ed25519.pub".text = sshKeys.launchpadMainWithComment + "\n";
    };

    sessionVariables = {
      PYTHONDONTWRITEBYTECODE = "1";
      KUBECTL_EXTERNAL_DIFF = "delta";
      PSKUBE_NO_COLOR = "1";
      # Docker: deliberately no DOCKER_HOST. The rootful daemon owns
      # /var/run/docker.sock, reachable via the docker group — the path
      # every tool hardcodes, so per-tool socket overrides are gone.
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

  # TR-100 machine report through prismacat, replacing the shared
  # fortune|cowsay banner from common/zsh.nix.
  matt.loginBanner = ''
    ${
      inputs.usgc-machine-report.packages.${pkgs.stdenv.hostPlatform.system}.usgc-machine-report
    }/bin/usgc_machine_report | ${
      inputs.mattware.packages.${pkgs.stdenv.hostPlatform.system}.prismacat
    }/bin/prismacat --theme "Dracula"
  '';

  programs = {
    # porthole client: xdg-open/$BROWSER/open route URLs to the daemon on
    # the Mac (hosts/darwin/home/porthole.nix) over the ssh RemoteForward.
    porthole.enable = true;

    # The (launchpad) prompt is starship's hostname module, which normally
    # shows only under ssh (SSH_CONNECTION set). Rex sessions here are not
    # ssh: rex-login-server spawns the shell, so the variable never exists.
    # This box is only ever viewed remotely, so always show the hostname.
    starship.settings.hostname.ssh_only = lib.mkForce false;

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
