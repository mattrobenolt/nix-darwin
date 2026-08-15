{ pkgs, ... }:

let
  nixSettings = import ../../../common/nix-settings.nix;

  # matt's daily key, served by the 1Password agent on the Mac. Also the
  # EC2 keypair (var.ssh_public_key in infra/launchpad), so a fresh AMI
  # birth injects this same key for root. There is no separate bootstrap
  # key.
  mattMainKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTuvuCDtmFBcTEkfOyx1NlUJZPcCJ76cChOt8ACBGKG matt@ydekproductions.com";
in
{
  imports = [ ./hardware.nix ];

  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "26.05";

  networking = {
    hostName = "launchpad";
    # The VPC has no IPv6 CIDR; disable it in the kernel too, so nothing
    # attempts link-local v6. The Corefile also sinks AAAA answers.
    enableIPv6 = false;
    # Everything goes through the local coredns; keep dhcpcd's learned
    # VPC resolver out of resolv.conf (coredns already forwards there).
    nameservers = [ "127.0.0.1" ];
    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  services = {
    coredns = {
      enable = true;
      config = builtins.readFile ./files/Corefile;
    };
    # Never. coredns owns :53.
    resolved.enable = false;

    syncthing = {
      enable = true;
      # Run as matt: synced files land owned by the same user the agents
      # run as. State lives in /var/lib/syncthing (module default).
      user = "matt";
      group = "users";
      # Opens the NixOS firewall for 22000 tcp/udp; the SG allows it from
      # anywhere. Within syncthing's security model. The GUI stays on
      # 127.0.0.1:8384 — reach it with ssh -L 8384:localhost:8384.
      openDefaultPorts = true;

      settings = {
        devices."Matts-MBP" = {
          id = "2PAUDHA-72WFQLX-B6DJG63-VQXOUKE-FJJ345J-APVEJRI-VRG6VVM-F4CQ2Q2";
          # Remote link over a home upload; everything bulky is text. LZ4
          # is cheap on both ends.
          compression = "always";
        };
        folders."pi-agent" = {
          # ~/.pi/agent, scoped per docs/ec2-agent-box.md. Ignore patterns:
          # files/stignore-pi-agent, symlinked into place on both sides.
          # Same absolute path as the Mac — that's the point of the
          # /Users/matt home.
          path = "/Users/matt/.pi/agent";
          devices = [ "Matts-MBP" ];
          # Sync permission bits so auth.json keeps 0600.
          ignorePerms = false;
        };
      };
    };
  };

  # The syncthing module only creates its state dir for the default
  # "syncthing" user; we run as matt, so make it ourselves.
  systemd.tmpfiles.rules = [
    "d /var/lib/syncthing 0700 matt users -"
    # Parent of the unconventional home (see users.users.matt.home).
    "d /Users 0755 root root -"
  ];

  environment.systemPackages = with pkgs; [
    curl
    file
    git
    neovim
    nixfmt
    strace
    wget
  ];

  programs.zsh.enable = true;

  users.users = {
    # nixos-rebuild target + daily login. The AMI also injects the EC2
    # keypair (= the same key) for root at boot.
    root.openssh.authorizedKeys.keys = [
      mattMainKey
    ];

    matt = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      # Deliberately /Users/matt, not /home/matt: the synced pi state is
      # full of absolute Mac paths (trust.json, session keys, skills).
      # Matching the Mac's home path makes the synced tree correct by
      # construction. Linux does not care; passwd drives $HOME.
      home = "/Users/matt";
      createHome = true;
      openssh.authorizedKeys.keys = [
        mattMainKey
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = nixSettings.substituters;
      extra-trusted-public-keys = nixSettings.trustedPublicKeys;
      trusted-users = nixSettings.trustedUsers;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
