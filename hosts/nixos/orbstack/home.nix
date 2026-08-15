{
  config,
  pkgs,
  osConfig,
  ...
}:

let
  macHome = "/mnt/mac/Users/matt";
  mkSymlink = path: {
    source = config.lib.file.mkOutOfStoreSymlink path;
  };
  piBaseWrapper = pkgs.writeShellScriptBin "pi-base" ''
    set -euo pipefail

    PI_HOME="$HOME/.pi/agent"
    PI_BIN="$PI_HOME/node_modules/.bin/pi"

    if [ ! -x "$PI_BIN" ]; then
      echo "pi is not installed in $PI_HOME" >&2
      echo "Run: cd $PI_HOME && npm install" >&2
      exit 1
    fi

    exec "$PI_BIN" "$@"
  '';
  piProfileWrapper = pkgs.writeShellScriptBin "pi-profile" ''
    set -euo pipefail

    PI_HOME="$HOME/.pi/agent"
    PI_PROFILE_BIN="$PI_HOME/node_modules/.bin/pi-profile"

    if [ ! -x "$PI_PROFILE_BIN" ]; then
      echo "pi-profile is not installed in $PI_HOME" >&2
      echo "Run: cd $PI_HOME && npm install" >&2
      exit 1
    fi

    exec "$PI_PROFILE_BIN" "$@"
  '';
  piWrapper = pkgs.writeShellScriptBin "pi" ''
    exec ${piProfileWrapper}/bin/pi-profile run default -- "$@"
  '';
  piWorkWrapper = pkgs.writeShellScriptBin "pi-work" ''
    exec ${piProfileWrapper}/bin/pi-profile run work -- "$@"
  '';
  piPersonalWrapper = pkgs.writeShellScriptBin "pi-personal" ''
    exec ${piProfileWrapper}/bin/pi-profile run personal -- "$@"
  '';
  claudeShared = [
    "CLAUDE.md"
    "settings.json"
    "agents"
    "agent-memory"
    "plans"
    "todos"
    "plugins"
    "statusline-command.sh"
    "projects"
    "hooks"
    "caffeine"
  ];
  codexShared = [
    "AGENTS.md"
    "config.toml"
    "memories"
    "rules"
    "plugins"
    "sessions"
    "session_index.jsonl"
    "history.jsonl"
    "internal_storage.json"
    "state_5.sqlite"
    "sqlite"
  ];
in

{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix.
  imports = [ ../home.nix ];

  home = {
    stateVersion = "26.05";

    sessionVariables = {
      DOCKER_HOST = "unix:///run/podman/podman.sock";
    };

    file = {
      ".agents/skills".source = config.lib.file.mkOutOfStoreSymlink "${macHome}/.agents/skills";
      ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "/home/matt/.agents/skills";
      ".pi".source = config.lib.file.mkOutOfStoreSymlink "${macHome}/.pi";
      ".cache/qmd".source = config.lib.file.mkOutOfStoreSymlink "${macHome}/.cache/qmd";
      "code".source = config.lib.file.mkOutOfStoreSymlink "/Users/matt/code";
    }
    // builtins.listToAttrs (
      map (name: {
        name = ".claude/${name}";
        value = mkSymlink "${macHome}/.claude/${name}";
      }) claudeShared
    )
    // builtins.listToAttrs (
      map (name: {
        name = ".codex/${name}";
        value = mkSymlink "${macHome}/.codex/${name}";
      }) codexShared
    );

    # orbstack-specific: pi runs from the Mac's ~/.pi/agent via symlink.
    packages = [
      piBaseWrapper
      piWrapper
      piWorkWrapper
      piPersonalWrapper
      piProfileWrapper
    ];
  };

  programs = {
    zsh = {
      shellAliases = {
        nixos-update = "sudo nixos-rebuild switch --flake /mnt/mac/Users/matt/.config/nix-darwin#${osConfig.networking.hostName}";
      };
    };
  };
}
