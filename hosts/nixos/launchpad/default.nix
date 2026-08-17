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
    # Tailnet MagicDNS search domain (tailscale runs with
    # --accept-dns=false, so it does not manage this for us). The ts.net.
    # zone in the Corefile does the actual resolution.
    search = [ "tail45c3.ts.net" ];
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
        # The NAS on the home LAN (reaches us via the EIP). Only shares
        # the code folder — pi-agent stays Mac<->box.
        devices.diskstation = {
          id = "A7WIK2G-FOFTUBX-DQPOHTW-VP2CCSG-6HMRSWU-DDF26HB-X2VL5OH-QXMBBQG";
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
          devices = [
            "Matts-MBP"
            "diskstation"
          ];
          # Match the Mac's folder: sync permission bits. Builds run from
          # this tree; scripts need their +x.
          ignorePerms = false;
        };
      };
    };
  };

  age.secrets = {
    syncthing-key = {
      file = ../../../secrets/syncthing-key.pem.age;
      owner = "matt";
      group = "users";
      mode = "0400";
    };
    syncthing-cert = {
      file = ../../../secrets/syncthing-cert.pem.age;
      owner = "matt";
      group = "users";
      mode = "0444";
    };
    # The box's user SSH keypair (git push + signing identity). Decrypted
    # straight into place; the pub half is not secret and ships as text.
    launchpad-id-ed25519 = {
      file = ../../../secrets/launchpad-id-ed25519.age;
      path = "/Users/matt/.ssh/id_ed25519";
      owner = "matt";
      group = "users";
      mode = "0600";
      symlink = false;
    };
    # The box's tailnet node identity, restored into place at activation
    # (see system.activationScripts). Rebirths rejoin as the same node.
    tailscaled-state = {
      file = ../../../secrets/tailscaled-state.age;
      mode = "0400";
    };
  };

  # Tailscale daemon. The box is on the tailnet (manual `tailscale up`
  # once). Once the corp-tailnet tagged-device auth key exists, it becomes
  # an agenix secret + services.tailscale.authKeyFile and the manual step
  # goes away.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Never let tailscaled take over DNS: coredns owns :53 on this box and
    # the Corefile already forwards ts.net. to 100.100.100.100. The default
    # accept-dns rewrote /etc/resolv.conf once — never again.
    extraUpFlags = [ "--accept-dns=false" ];
  };

  systemd = {
    # The syncthing module only creates its state dir for the default
    # "syncthing" user; we run as matt, so make it ourselves.
    tmpfiles.rules = [
      "d /var/lib/syncthing 0700 matt users -"
      # Parent of the unconventional home (see users.users.matt.home).
      "d /Users 0755 root root -"
    ];

    # qmd MCP daemon (memory search backend for pi). On the Mac this is
    # started lazily by the hourly curation script; here the service manager
    # owns it. Foreground mode — no --daemon flag, systemd supervises.
    # Localhost only (8181); no SG/firewall exposure. State and models live
    # in matt's ~/.cache/qmd (box-local, deliberately unsynced).
    # pkgs.qmd carries its llama.cpp backend (built at package time in
    # mattware's qmd) — no runtime builds, no wrappers.
    services.qmd = {
      description = "qmd MCP daemon (pi memory search)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "matt";
        Group = "users";
        ExecStart = "${pkgs.qmd}/bin/qmd mcp --http";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Keep the box's search index fresh as syncthing lands new memory.
    # Incremental; reads synced memory/, writes only the box-local index.
    services.qmd-embed = {
      description = "qmd incremental re-index";
      serviceConfig = {
        Type = "oneshot";
        User = "matt";
        Group = "users";
        ExecStart = "${pkgs.qmd}/bin/qmd embed";
      };
    };

    timers.qmd-embed = {
      description = "qmd re-index every 15min";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/15";
        # Box stops and starts; run missed embeds at boot.
        Persistent = true;
      };
    };
  };

  # matt-owned dirs, created in an ACTIVATION SCRIPT (not tmpfiles):
  # activation scripts run before any unit (home-manager-matt.service) and
  # before agenix, so HM's symlinks and the agenix id_ed25519 write always
  # find matt-owned parents. tmpfiles runs as a unit — after activation —
  # and raced/lost this on the fresh-volume rebuild (learned the hard way).
  # syncthing refuses to adopt a dir without its .stfolder marker, hence
  # the marker dirs.
  system.activationScripts = {
    launchpad-dirs = {
      deps = [ "users" ]; # matt must exist for install -o
      text = ''
        install -d -m 700 -o matt -g users /Users/matt/.ssh
        install -d -m 755 -o matt -g users /Users/matt/.pi /Users/matt/.pi/agent /Users/matt/.pi/agent/.stfolder
        install -d -m 755 -o matt -g users /Users/matt/code /Users/matt/code/.stfolder
      '';
    };
    # Merged with the agenix module's own deps (specialfs): our dirs first.
    agenix.deps = [ "launchpad-dirs" ];

    # Restore the pinned tailscale node identity after agenix decrypts it,
    # before tailscaled starts. Rebirths rejoin the tailnet as the same
    # node (launchpad, same 100.x IP) with no auth key ceremony.
    launchpad-tailscale-state = {
      deps = [ "agenix" ];
      text = ''
        install -d -m 700 /var/lib/tailscale
        install -m 600 /run/agenix/tailscaled-state /var/lib/tailscale/tailscaled.state
      '';
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

  # Pin GitHub's host keys (source: https://api.github.com/meta) so the
  # box's outbound ssh never hits an interactive first-connect prompt —
  # there is nobody to answer it on an unattended box.
  programs.ssh.knownHosts = {
    github-ed25519 = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    github-ecdsa = {
      hostNames = [ "github.com" ];
      publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
    };
    github-rsa = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
    };
  };

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
      # porthole's RemoteForward re-binds ~/.porthole.sock on every new
      # ssh session; unlink the stale socket instead of refusing.
      StreamLocalBindUnlink = true;
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
      # 8GB box: the kernel OOM-killed nix (6GB+ anon) realizing a big
      # generation. Everything SHOULD substitute from cache; when it
      # doesn't, build gently rather than die.
      max-jobs = 2;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Same story for memory: zram alone wasn't enough on the smaller box.
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];
}
