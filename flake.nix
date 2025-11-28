{
  description = "Matt's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # System packages from nixpkgs
          environment.systemPackages = with pkgs; [
            _1password-cli
            aerc
            age
            appcleaner
            argocd
            asciinema
            atuin
            audacity
            automake
            awscli
            bat
            bats
            btop
            buf
            bun
            chafa
            cilium-cli
            claude-code
            codex
            cowsay
            deadnix
            delta
            difftastic
            direnv
            discord
            dust
            ec2-instance-selector
            entr
            etcd
            eza
            fastfetch
            fd
            fish
            foreman
            fortune
            fzf
            gh
            git
            glow
            gnutar
            go
            golangci-lint
            graphviz
            grpcurl
            helix
            hexyl
            htop
            hwatch
            hyperfine
            image_optim
            imagemagick
            jaq
            jinja2-cli
            jo
            jq
            just
            kustomize
            lazygit
            libffi
            lolcat
            luarocks
            mariadb.client
            mkcert
            mtr
            mycli
            neovim
            nghttp2
            nil
            nix-direnv
            nixd
            nixfmt-rfc-style
            nodejs
            nomad
            nushell
            obsidian
            packer
            pandoc
            pgbouncer
            pgcli
            pkg-config
            postgresql
            pscale
            pstree
            pyright
            python3
            ripgrep
            ruff
            scc
            scdoc
            sentry-cli
            shellcheck
            socat
            starship
            statix
            swift-format
            tcping-rs
            telegram-desktop
            terminal-notifier
            terraform
            terragrunt
            timg
            tmux
            upx
            utm
            uv
            vault
            vector
            vim
            w3m
            watch
            watchexec
            weechat
            wget
            wrk
            yazi
            yj
            yq
            zellij
            zig
            zoxide
            zsh
          ];

          # Set the primary user for user-specific options like Homebrew
          # This is required because nix-darwin now runs as root
          system.primaryUser = "matt";

          # Homebrew integration
          homebrew = {
            enable = true;

            onActivation = {
              autoUpdate = true;
              upgrade = true;
              cleanup = "zap";
            };

            # Taps for formulae from custom repositories
            taps = [
              "sst/tap"
            ];

            # Formulae to install via Homebrew
            # These are either tap-based, version-specific, or not available in nixpkgs
            brews = [
              "sst/tap/opencode"

              "coredns"
              "syncthing"
              "tailscale"
            ];

            # GUI applications (casks)
            # Keep all GUI apps in Homebrew for better macOS integration
            casks = [
              "chatgpt"
              "claude"
              # "docker"  # Not using - using OrbStack instead
              # "docker-desktop"  # Not using - using OrbStack instead
              "font-hack"
              "font-hack-nerd-font"
              "font-inter"
              "font-jetbrains-mono-nerd-font"
              "font-symbols-only-nerd-font"
              "gcloud-cli"
              "istat-menus"
              "messenger"
              "orbstack"
              "plexamp"
              "raycast"
              "session-manager-plugin"
              "vanilla"
              "vibetunnel"
            ];
          };

          # Disable nix-darwin's Nix management since we're using Determinate Nix
          # Determinate Nix manages its own daemon and configuration
          nix.enable = false;

          # macOS System Settings
          # These match your current macOS preferences
          system.defaults = {
            # Dock settings
            dock = {
              autohide = true;
              orientation = "bottom";
              show-recents = false;
              tilesize = 67;
            };

            # Finder settings
            finder = {
              AppleShowAllExtensions = true;
              ShowPathbar = true;
              ShowStatusBar = false;
              FXPreferredViewStyle = "clmv";
            };

            # Global macOS settings
            NSGlobalDomain = {
              AppleInterfaceStyle = "Dark";
              AppleShowAllExtensions = true;
              InitialKeyRepeat = 15;
              KeyRepeat = 1;
            };

            # Trackpad settings
            trackpad = {
              Clicking = false;
              TrackpadRightClick = true;
              TrackpadThreeFingerDrag = false;
            };
          };

          # Networking
          networking = {
            computerName = "Matt's MacBook Pro";
            hostName = "Matts-MacBook-Pro";
            localHostName = "Matts-MacBook-Pro";
            knownNetworkServices = [ "Wi-Fi" ];

            dns = [ "127.0.0.1" ];

            search = [
              "tail45c3.ts.net"
              "local"
            ];

          };

          # Enforce DNS to localhost (for coredns)
          # macOS DHCP likes to override DNS, this ensures it stays pointed to coredns
          launchd.daemons.enforce-dns = {
            script = ''
              if /usr/sbin/networksetup -getinfo "Wi-Fi" &>/dev/null 2>&1; then
                /usr/sbin/networksetup -setdnsservers "Wi-Fi" 127.0.0.1 2>/dev/null || true
              fi
            '';
            serviceConfig = {
              RunAtLoad = true;
              StartInterval = 3600;
            };
          };

          # Sudo configuration
          security.pam.services.sudo_local.touchIdAuth = true;
          security.sudo.extraConfig = ''
            Defaults timestamp_timeout=1440
          '';

          # Enable fish shell integration
          # This sets up PATH and nix-darwin environment in fish
          programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          nixpkgs.config.allowUnfree = true;
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Matts-MacBook-Pro
      darwinConfigurations."Matts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.matt = import ./home.nix;
          }
        ];
      };
    };
}
