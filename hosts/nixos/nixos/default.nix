{
  config,
  pkgs,
  inputs,
  ...
}:

let
  nixSettings = import ../../../common/nix-settings.nix;
in
{
  imports = [ ./hardware-configuration.nix ];

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

    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          helium
        '';
        mode = "0755";
      };
    };
  };

  fonts.packages = with pkgs; [
    hack-font
    inter
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  security = {
    sudo.wheelNeedsPassword = false;
    polkit.enable = true;
  };

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services = {
    getty.autologinUser = "matt";
    xserver.videoDrivers = [ "nvidia" ];

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "matt" ];
    };

    zsh.enable = true;
    dconf.enable = true;

    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

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
