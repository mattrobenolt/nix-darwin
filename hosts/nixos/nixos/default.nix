{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 2;
      consoleMode = "max";
    };
    timeout = 5;
    efi.canTouchEfiVariables = true;
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
        url = "https://github.com/mattrobenolt.keys";
        sha256 = "1r9mdknkblj86zp5kzc6mw4a8c2qwwymik86wfgfzynlh6hq49fi";
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
      psmisc
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
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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
      substituters = [
        "https://hyprland.cachix.org"
        "https://hyprshell.cachix.org"
        "https://ghostty.cachix.org"
        "https://zed.cachix.org"
        "https://cache.garnix.io"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "hyprshell.cachix.org-1:Ri7eg9v4s0u9XXi3J6FlrkrVB/ms7TFVKxilBHs2weA="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "matt" ];
      download-buffer-size = "128M";
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
