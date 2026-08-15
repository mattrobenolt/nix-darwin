{ pkgs, inputs, ... }:

# Shared home-manager layer for all NixOS hosts (orbstack, nixos, launchpad).
# home-common.nix holds the cross-OS config (Mac included); this adds the
# Linux-shared package set. Host-specific bits stay in each host's own home.
{
  imports = [ ../../home-common.nix ];

  home = {
    username = "matt";
    homeDirectory = "/home/matt";
    sessionPath = [ "$HOME/.local/bin" ];

    packages = with pkgs; [
      (ast-grep {
        languages.zig = {
          grammar = tree-sitter-grammars.tree-sitter-zig;
          extensions = [ "zig" ];
        };
      })
      atuin
      awscli2
      bun
      curl
      deadnix
      dnsutils
      dust
      entr
      fastfetch
      fd
      file
      fzf
      gh
      glow
      gnutar
      google-cloud-sdk
      hexyl
      hwatch
      hyperfine
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      jq
      just
      mtr
      nixd
      nixfmt
      nodejs
      psmisc
      python3
      ripgrep
      rtk
      ruff
      socat
      statix
      strace
      uv
      wget
      yq
      zoxide
    ];
  };

  programs = {
    home-manager.enable = true;

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com".User = "git";
    };
  };
}
