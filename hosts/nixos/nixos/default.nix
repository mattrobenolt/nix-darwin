{ pkgs, ... }:

let
  nixSettings = import ../../../common/nix-settings.nix;
in
{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 2;
        consoleMode = "max";
      };
      timeout = 5;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  time.timeZone = "America/Los_Angeles";

  users.users.matt = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [
      (builtins.fetchurl {
        url = "https://mattrobenolt.com/id_ed25519.pub";
        sha256 = "sha256-seWKBEqvkd+YNtWUJjLkuR69SNDQ+3H1JayfbzTrB2M=";
      })
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      curl
      dig
      fd
      file
      git
      perl
      psmisc
      python3
      ripgrep
      strace
      vim
      wget
      zsh
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services = {
    getty.autologinUser = "matt";

    # Publish nixos.local (mDNS) so the Mac can drive remote rebuilds by
    # name (just desktop-check / desktop-apply).
    avahi = {
      enable = true;
      openFirewall = true;
      publish.enable = true;
      publish.addresses = true;
    };

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Pure terminal host: no audio stack.
  };

  programs = {
    _1password.enable = true;

    zsh.enable = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        xz
        openssl
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    enable = true;
    settings = {
      extra-substituters = nixSettings.substituters;
      extra-trusted-public-keys = nixSettings.trustedPublicKeys;
      trusted-users = nixSettings.trustedUsers;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      download-buffer-size = nixSettings.downloadBufferSize;
      eval-cache = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  system.stateVersion = "26.05";
}
