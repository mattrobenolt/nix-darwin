{
  pkgs,
  lib,
  config,
  ...
}:

let
  nixSettings = import ../../../common/nix-settings.nix;
  sshKeys = import ../../../common/ssh-keys.nix { inherit lib; };

  # matt's daily key (canonical source: https://mattrobenolt.com/id_ed25519.pub).
  # Also the EC2 keypair, so a fresh AMI birth injects this same key for
  # root. There is no separate bootstrap key.
  mattMainKey = sshKeys.mattMainWithComment;

  # PATH for the qmd systemd units: the bun wrapper bootstraps qmd into
  # $HOME and node-llama-cpp compiles its backend on first model load.
  qmdUnitPath = lib.mkForce (
    lib.makeBinPath [
      pkgs.nodejs # qmd spawns node subprocesses even when run under bun
      pkgs.bun
      pkgs.cmake
      pkgs.gnumake
      pkgs.gcc
      pkgs.coreutils
    ]
  );
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
      # Pinned device identity, decrypted by agenix from the repo at
      # activation. Rebirths keep the same syncthing device ID — no
      # re-pairing. Recipients in secrets/secrets.nix.
      key = config.age.secrets.syncthing-key.path;
      cert = config.age.secrets.syncthing-cert.path;
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

        folders."bjkky-xjf6r" = {
          # The existing ~/code share (id is fixed by the mesh, do not
          # rename). ~/code/.stignore is a one-line include of the synced
          # .stignore-shared on every node.
          path = "/Users/matt/code";
          label = "code";
          devices = [ "Matts-MBP" ];
          # Match the Mac's folder: sync permission bits. Builds run from
          # this tree; scripts need their +x.
          ignorePerms = false;
        };
      };
    };
  };

  age.secrets.syncthing-key = {
    file = ../../../secrets/syncthing-key.pem.age;
    owner = "matt";
    group = "users";
    mode = "0400";
  };
  age.secrets.syncthing-cert = {
    file = ../../../secrets/syncthing-cert.pem.age;
    owner = "matt";
    group = "users";
    mode = "0444";
  };

  # The box's user SSH keypair (git push + signing identity). Decrypted
  # straight into place; the pub half is not secret and ships as text.
  age.secrets.launchpad-id-ed25519 = {
    file = ../../../secrets/launchpad-id-ed25519.age;
    path = "/Users/matt/.ssh/id_ed25519";
    owner = "matt";
    group = "users";
    mode = "0600";
    symlink = false;
  };

  # Tailscale daemon. Auth is a manual one-time step: the box joins the
  # corp tailnet as a tagged device (auth key via 1Password) — once that
  # lands, the SG's port 22 rule can go. coredns already forwards ts.net.
  # to 100.100.100.100 in anticipation.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # The syncthing module only creates its state dir for the default
  # "syncthing" user; we run as matt, so make it ourselves.
  systemd.tmpfiles.rules = [
    "d /var/lib/syncthing 0700 matt users -"
    # Parent of the unconventional home (see users.users.matt.home).
    "d /Users 0755 root root -"
  ];

  # qmd MCP daemon (memory search backend for pi). On the Mac this is
  # started lazily by the hourly curation script; here the service manager
  # owns it. Foreground mode — no --daemon flag, systemd supervises.
  # Localhost only (8181); no SG/firewall exposure. State and models live
  # in matt's ~/.cache/qmd (box-local, deliberately unsynced).
  #
  # NOTE: uses the bun-installed qmd wrapper (~/.local/bin/qmd), not
  # pkgs.qmd — see home.nix for why (node-llama-cpp linux-aarch64 gap).
  # PATH includes build tools: the wrapper's first model use compiles
  # llama.cpp from source (one-time).
  systemd.services.qmd = {
    description = "qmd MCP daemon (pi memory search)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment.PATH = qmdUnitPath;
    serviceConfig = {
      Type = "simple";
      User = "matt";
      Group = "users";
      ExecStart = "/Users/matt/.local/bin/qmd mcp --http";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Keep the box's search index fresh as syncthing lands new memory.
  # Incremental; reads synced memory/, writes only the box-local index.
  systemd.services.qmd-embed = {
    description = "qmd incremental re-index";
    environment.PATH = qmdUnitPath;
    serviceConfig = {
      Type = "oneshot";
      User = "matt";
      Group = "users";
      ExecStart = "/Users/matt/.local/bin/qmd embed";
    };
  };

  systemd.timers.qmd-embed = {
    description = "qmd re-index every 15min";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/15";
      # Box stops and starts; run missed embeds at boot.
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    file
    git
    neovim
    nixfmt
    strace
    wget
  ];

  nixpkgs.config.allowUnfree = true;

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
    # ed25519 only. The key is pinned (private half lives in the launchpad
    # 1Password vault, installed by scripts/launchpad-bootstrap on rebirth),
    # which also makes it the agenix identity. Same fingerprint forever.
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
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
