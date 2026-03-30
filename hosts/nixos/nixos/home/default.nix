{ pkgs, ... }:
{
  imports = [
    ../../../../common/atuin.nix
    ../../../../common/bat.nix
    ../../../../common/btop.nix
    ../../../../common/delta.nix
    ../../../../common/direnv.nix
    ../../../../common/eza.nix
    ../../../../common/htop.nix
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
    ./neovim.nix
    ./ssh.nix
    ./waybar.nix
    ./zsh.nix
  ];

  home = {
    stateVersion = "26.05";
    username = "matt";
    homeDirectory = "/home/matt";

    packages = with pkgs; [
      btop
      curl
      delta
      eza
      fastfetch
      fd
      file
      hexyl
      htop
      gh
      hypridle
      hyprlock
      hyprpolkitagent
      hyprshutdown
      hyprsunset
      nixd
      jq
      just
      nixfmt
      psmisc
      ripgrep
      strace
      wget
      wl-clip-persist
      wl-clipboard
      pulseaudio
      claude-code
      codex

      # LSPs (system-wide)
      nixd
      ruff
      uv # For uvx ty (Python type checker)

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
