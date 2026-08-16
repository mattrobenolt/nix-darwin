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

  # Matches users.users.matt.home: identical absolute paths to the Mac so
  # synced pi state (trust.json, sessions, skills) resolves correctly.
  home.homeDirectory = lib.mkForce "/Users/matt";

  home.packages = [
    piWrapper
    # Secrets get seeded from 1Password. (awscli2 comes from the shared
    # NixOS layer.)
    pkgs._1password-cli
    # Build tools so node-llama-cpp can compile its llama.cpp backend and
    # better-sqlite3 its binding on first use (no linux-aarch64 prebuilt
    # exists for either). Used by ~/.local/bin/qmd.
    pkgs.cmake
    pkgs.gnumake
    pkgs.gcc
    pkgs.python3
  ];

  # pkgs.qmd (from home-common) cannot run embeddings on linux-aarch64:
  # node-llama-cpp has no CPU prebuilt for the platform, and it can only
  # source-build into its own package dir — read-only in the nix store.
  # So qmd here is the bun-installed package in a writable dir (same pattern
  # as the Mac's launchd wrapper in work.nix), shadowing pkgs.qmd via
  # ~/.local/bin (first in sessionPath). The systemd qmd units reference
  # this wrapper by absolute path.
  home.file.".local/bin/qmd" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # 2.5.3 = latest on the npm registry. (pkgs.qmd reports 2.6.3, but
      # that tracks a git tag; npm lags. Schema-compatible in practice.)
      QMD_DIR="$HOME/.local/share/qmd/2.5.3"
      QMD_BIN="$QMD_DIR/node_modules/.bin/qmd"

      if [ ! -x "$QMD_BIN" ]; then
        mkdir -p "$QMD_DIR"
        (cd "$QMD_DIR" && ${pkgs.bun}/bin/bun add --trust @tobilu/qmd@2.5.3)
      fi

      # Two runtime constraints baked in:
      # - bun runtime for the main process: qmd then uses bun:sqlite,
      #   sidestepping better-sqlite3's missing node-v137-linux-arm64 prebuilt.
      # - node 26 for qmd's spawned node child: node 24.19.0 has the
      #   RemoveEnvironmentCleanupHook teardown regression that crashes
      #   better-sqlite3 on exit (nodejs/node#63923); fixed in 26.x.
      #   better-sqlite3's binding is ABI-locked — rebuild it when bumping
      #   this (node-gyp rebuild with this node first in PATH).
      export PATH="${pkgs.nodejs_26}/bin:$PATH"
      exec ${pkgs.bun}/bin/bun "$QMD_DIR/node_modules/@tobilu/qmd/bin/qmd" "$@"
    '';
  };

  # Box-side herdr server config. Client-side rendering settings stay in
  # the Mac's config — in --remote mode the local client owns them.
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [update]
    version_check = false
    manifest_check = false

    [session]
    resume_agents_on_restore = true
  '';

  # Canonical ignore set for the pi-agent syncthing folder. The folder is
  # created by syncthing itself on first share; this symlink pre-exists so
  # the ignores are in effect before the first pull. The Mac side symlinks
  # the same file from this repo checkout.
  home.file.".pi/agent/.stignore".source = ./files/stignore-pi-agent;

  # ~/code share: repo-managed literal ignore list. Do NOT use
  # "#include .stignore-shared" here — the shared file only exists after
  # the first sync, and a missing include fails ignore parsing, which
  # blocks that sync (chicken-and-egg, learned the hard way).
  home.file."code/.stignore".source = ./files/stignore-code;

  # Public half of the box's keypair (the private half is an agenix secret,
  # see default.nix).
  home.file.".ssh/id_ed25519.pub".text =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII13XL4pqymylPqF41vFZP74+91X5O017M/Tu7Jb6MR3 matt@launchpad\n";

  # aws-login: headless SSO login flags (see infra/launchpad/README.md).
  # Usage: aws-login --profile <name>
  programs.zsh.shellAliases = {
    aws-login = "aws sso login --use-device-code --no-browser";
  };

  # 1Password service account token lives ONLY on disk (0600), never in the
  # nix store. Loaded per shell when present. See README "Secrets" — and
  # note systemd services do not get this; if one ever needs op, give the
  # unit an EnvironmentFile pointing at the same file.
  home.sessionVariablesExtra = ''
    if [ -r "$HOME/.config/op/service-account-token" ]; then
      export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$HOME/.config/op/service-account-token")"
    fi
  '';

  programs.git = {
    # The box signs with its own key, registered on GitHub as a signing key
    # (the shared config points at matt's Mac key, which does not exist here).
    signing = {
      # Private key path, not the pubkey: with no ssh agent on the box,
      # git/ssh-keygen signs with the file directly.
      key = lib.mkForce "/Users/matt/.ssh/id_ed25519";
      signByDefault = lib.mkForce true;
    };
  };
}
