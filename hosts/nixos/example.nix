{ config, pkgs, ... }:

{
  # Example NixOS configuration
  # Copy this file and customize for each NixOS machine

  # Enable nix flakes and command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.enable = true;  # Override common.nix's false setting

  # Bootloader (customize based on your system)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos-example";  # Change this
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "America/New_York";  # Change this

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # User account
  users.users.matt = {
    isNormalUser = true;
    description = "Matt";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # Enable sudo with Touch ID equivalent (if supported hardware)
  security.sudo.wheelNeedsPassword = false;  # or configure as needed

  # Services
  services.openssh.enable = true;

  # Optional: Docker
  # virtualisation.docker.enable = true;

  # System-wide packages (in addition to common.nix)
  environment.systemPackages = with pkgs; [
    # Add NixOS-specific packages here
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";  # Did you read the comment?
}
