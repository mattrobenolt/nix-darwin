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
  piWrapper = pkgs.writeShellScriptBin "pi" ''
    set -euo pipefail

    PI_HOME="$HOME/.pi/agent"
    PI_BIN="$PI_HOME/node_modules/.bin/pi"
    PI_PROFILE_SCRIPT="$PI_HOME/scripts/pi-profile"

    if [ ! -x "$PI_BIN" ]; then
      echo "pi is not installed in $PI_HOME" >&2
      echo "Run: cd $PI_HOME && npm install" >&2
      exit 1
    fi

    PI_BIN="$PI_BIN" exec "$PI_PROFILE_SCRIPT" "$@"
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
  ];
in

{
  imports = [ ../../../home-common.nix ];

  home = {
    username = "matt";
    homeDirectory = "/home/matt";
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
    );

    packages = with pkgs; [
      btop
      bun
      fastfetch
      fd
      hexyl
      htop
      jq
      nixd
      nixfmt
      nodejs
      ripgrep
      uv
      llm-agents.claude-code
      llm-agents.codex
      piWrapper
    ];
  };

  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      defaultKeymap = "emacs";
      shellAliases = {
        nixos-update = "sudo nixos-rebuild switch --flake /mnt/mac/Users/matt/.config/nix-darwin#${osConfig.networking.hostName}";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "github.com" = {
          user = "git";
        };
      };
    };
  };
}
