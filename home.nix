{ lib, ... }:

{
  # Base home-manager configuration
  # This file sets up the basic home-manager settings and imports machine-specific configs

  imports = [
    ./home-common.nix # Shared across all machines
    ./hosts/darwin/home.nix # Darwin-specific config
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home = {
    username = lib.mkForce "matt";
    homeDirectory = lib.mkForce "/Users/matt";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
