{ pkgs, ... }:
{
  imports = [
    ../../../../common/atuin.nix
    ../../../../common/bat.nix
    ../../../../common/btop.nix
    ../../../../common/delta.nix
    ../../../../common/direnv.nix
    ../../../../common/eza.nix
    ../../../../common/git.nix
    ../../../../common/htop.nix
    ../../../../common/neovim.nix
    ../../../../common/starship.nix
    ../../../../common/yazi.nix
    ../../../../common/zellij.nix
    ../../../../common/zoxide.nix
    ../../../../common/zsh.nix
    ./ghostty.nix
    ./git.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    ./hyprshell.nix
    ./hyprsunset.nix
    ./ssh.nix
    ./waybar.nix
    ./zsh.nix
  ];

  home = {
    stateVersion = "26.05";
    username = "matt";
    homeDirectory = "/home/matt";

    packages = with pkgs; [
      curl
      fastfetch
      fd
      file
      hexyl
      gh
      hypridle
      hyprlock
      hyprpolkitagent
      hyprshutdown
      hyprsunset
      jq
      just
      nixd
      nixfmt
      psmisc
      ripgrep
      ruff
      strace
      uv
      wget
      wl-clip-persist
      wl-clipboard
      pulseaudio
      claude-code
      codex
      helium
      zed-editor
    ];

    pointerCursor = {
      gtk.enable = true;
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  programs = {
    firefox.enable = true;
  };
}
