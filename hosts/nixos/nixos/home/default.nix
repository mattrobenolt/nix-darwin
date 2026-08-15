{ pkgs, ... }:
{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix. This file keeps only the desktop/GUI specifics.
  imports = [
    ../../home.nix
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

    packages = with pkgs; [
      helium
      hypridle
      hyprlock
      hyprpolkitagent
      hyprshutdown
      hyprsunset
      pulseaudio
      wl-clip-persist
      wl-clipboard
      zed-preview
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
