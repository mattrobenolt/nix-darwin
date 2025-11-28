{ pkgs, ... }:

{
  # Work MacBook Pro specific configuration

  # Work-specific packages
  environment.systemPackages = with pkgs; [
    # Work development tools
    argocd
    cilium-cli
    kubectl
    kustomize
    terraform
    terragrunt
    packer
    nomad
    vault
    vector
    etcd

    # Cloud tools
    awscli
    ec2-instance-selector

    # Databases
    postgresql
    pgbouncer
    pgcli
    mariadb.client
    mycli
    pscale

    # Build/deploy tools
    foreman
    buf
    sentry-cli
    upx

    # Work-specific languages/tools
    golangci-lint
    swift-format
    pyright
    ruff
    luarocks
    uv
    zig

    # Container/VM tools (via nix)
    utm

    # Work editors/IDEs
    helix
    claude-code

    # Documentation/notes
    pandoc
    scdoc
    glow
    obsidian

    # Media tools (for work presentations, etc.)
    imagemagick
    image_optim
    chafa
    timg

    # Other work utilities
    _1password-cli
    age
    mkcert
    pstree
    scc
    tcping-rs
    codex
    appcleaner
    aerc
    asciinema
    audacity
    automake
    bats
    discord
    gnutar
    graphviz
    jinja2-cli
    jo
    libffi
    nghttp2
    nushell
    pkg-config
    shellcheck
    telegram-desktop
    vim
    w3m
    weechat
    yazi
  ];

  # Set the primary user for user-specific options like Homebrew
  system.primaryUser = "matt";

  # Homebrew integration (macOS GUI apps)
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # Work-specific taps
    taps = [
      "sst/tap"
    ];

    # Work-specific CLI tools (not in nixpkgs or need specific versions)
    brews = [
      "sst/tap/opencode"
      "coredns"      # Local DNS resolver
      "syncthing"    # File sync
      "tailscale"    # VPN/mesh network
    ];

    # GUI applications (better macOS integration via Homebrew)
    casks = [
      # AI tools
      "chatgpt"
      "claude"

      # Fonts
      "font-hack"
      "font-hack-nerd-font"
      "font-inter"
      "font-jetbrains-mono-nerd-font"
      "font-symbols-only-nerd-font"

      # Cloud tools
      "gcloud-cli"
      "session-manager-plugin"

      # Productivity
      "raycast"
      "istat-menus"
      "vanilla"

      # Communication
      "messenger"

      # Development
      "orbstack"      # Docker/container alternative
      "vibetunnel"

      # Media
      "plexamp"
    ];
  };

  # macOS System Settings
  system.defaults = {
    dock = {
      autohide = true;
      orientation = "bottom";
      show-recents = false;
      tilesize = 67;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = false;
      FXPreferredViewStyle = "clmv";  # Column view
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 1;
    };

    trackpad = {
      Clicking = false;              # Tap to click disabled
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };
  };

  # Networking configuration
  networking = {
    computerName = "Matt's MacBook Pro";
    hostName = "Matts-MacBook-Pro";
    localHostName = "Matts-MacBook-Pro";
    knownNetworkServices = [ "Wi-Fi" ];

    # Point to local coredns instance
    dns = [ "127.0.0.1" ];

    # DNS search domains (Tailscale MagicDNS + mDNS)
    search = [
      "tail45c3.ts.net"
      "local"
    ];
  };

  # DNS enforcement daemon
  # Ensures DNS stays pointed to coredns even when DHCP tries to override
  launchd.daemons.enforce-dns = {
    script = ''
      if /usr/sbin/networksetup -getinfo "Wi-Fi" &>/dev/null 2>&1; then
        /usr/sbin/networksetup -setdnsservers "Wi-Fi" 127.0.0.1 2>/dev/null || true
      fi
    '';
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 3600;  # Check every hour
    };
  };

  # Security configuration
  security.pam.services.sudo_local.touchIdAuth = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=1440
  '';

  # System metadata
  system.stateVersion = 6;

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
