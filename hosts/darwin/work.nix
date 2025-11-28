{ pkgs, ... }:

{
  # Work MacBook Pro specific configuration

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

    brews = [
      "sst/tap/opencode"
      "coredns"
      "syncthing"
      "tailscale"
    ];

    casks = [
      "chatgpt"
      "claude"
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

  # System configuration
  system = {
    # Set the primary user for user-specific options like Homebrew
    primaryUser = "matt";

    # System metadata
    stateVersion = 6;

    # macOS System Settings
    defaults = {
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
      FXPreferredViewStyle = "clmv"; # Column view
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 1;
    };

    trackpad = {
      Clicking = false; # Tap to click disabled
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };
  }; # end system.defaults
  }; # end system

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
      StartInterval = 3600; # Check every hour
    };
  };

  # Security configuration
  security.pam.services.sudo_local.touchIdAuth = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=1440
  '';

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
