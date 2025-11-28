{ lib, ... }:

{
  # This is your home-manager configuration
  # Start small and add more as you migrate your dotfiles

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

  # Starter configurations - these won't break your existing setup
  # Uncomment and customize as you migrate

  # programs.git = {
  #   enable = true;
  #   userName = "Matt";
  #   userEmail = "your-email@example.com";
  #   aliases = {
  #     st = "status";
  #     co = "checkout";
  #     br = "branch";
  #   };
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #     pull.rebase = true;
  #   };
  # };

  # programs.fish = {
  #   enable = true;
  #   shellAliases = {
  #     ll = "eza -la";
  #     g = "git";
  #   };
  # };

  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     # Your starship config here
  #   };
  # };
}
