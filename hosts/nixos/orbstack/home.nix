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
  claudeShared = [
    "settings.json"
    "agents"
    "agent-memory"
    "plans"
    "todos"
    "plugins"
    "statusline-command.sh"
    "projects"
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
      llm-agents.pi
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
