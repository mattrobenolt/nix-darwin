{ pkgs, matt-nixpkgs, ... }:

{
  # Work MacBook Pro specific configuration

  imports = [
    ./disable-bloat.nix
  ];

  # Package overrides
  nixpkgs.overlays = [
    # Use custom packaging from personal nixpkgs fork (matt_go, zlint, etc.)
    matt-nixpkgs.overlays.default

    (_final: prev: {
      # coredns build is broken in nixpkgs-unstable (bad patches), skip patches and tests
      coredns = prev.coredns.overrideAttrs (_oldAttrs: {
        postPatch = ""; # Skip broken patches
        doCheck = false; # Skip tests
      });
    })
  ];

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
    awscli2
    bats
    btop
    buf
    bun
    claude-code
    codex
    coredns
    cowsay
    deadnix
    delta
    difftastic
    dust
    ec2-instance-selector
    entr
    fish
    fortune
    fzf
    gh
    glow
    gnutar
    matt_go
    golangci-lint
    graphviz
    grpcurl
    hexyl
    hwatch
    hyperfine
    jaq
    jinja2-cli
    jo
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
    nghttp2
    nil
    nixd
    nixfmt-rfc-style
    nixfmt-tree
    nodejs
    obsidian
    packer
    pandoc
    pgbouncer
    pgcli
    postgresql
    pstree
    pyright
    python3
    ruff
    scc
    sentry-cli
    shellcheck
    socat
    statix
    swift
    swift-format
    tcping-rs
    telegram-desktop
    timg
    utm
    uv
    vector
    w3m
    watch
    watchexec
    weechat
    wrk
    yazi
    yj
    yq
    zig
    zoxide
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
      "scroll-reverser"
      "session-manager-plugin"
      "vanilla"
      "vibetunnel"
      "imageoptim"
      "discord"
      "slack"
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
        # Behavior improvements
        mru-spaces = false; # Don't auto-rearrange spaces
        show-process-indicators = true; # Show dots under running apps
        minimize-to-application = false; # Minimize into app icon
        # Animation disabling
        autohide-delay = 0.0; # No delay before dock appears
        autohide-time-modifier = 0.0; # Instant dock show/hide
        expose-animation-duration = 0.0; # Instant mission control
        launchanim = false; # Disable app launch bouncing
        mineffect = "scale"; # Faster minimize effect
      };

      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = false;
        FXPreferredViewStyle = "clmv"; # Column view
        # Behavior improvements
        FXEnableExtensionChangeWarning = false; # No warning when changing extensions
        _FXShowPosixPathInTitle = true; # Show full path in title
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 1;
        # Behavior improvements
        ApplePressAndHoldEnabled = false; # Enable key repeat instead of accent menu
        NSNavPanelExpandedStateForSaveMode = true; # Expanded save panel by default
        "com.apple.swipescrolldirection" = true; # Natural scrolling
        # Animation disabling
        NSAutomaticWindowAnimationsEnabled = false; # Disable window animations
        NSScrollAnimationEnabled = false; # Disable smooth scrolling animations
        NSUseAnimatedFocusRing = false; # Disable focus ring animation
        NSWindowResizeTime = 0.001; # Instant window resize
      };

      trackpad = {
        Clicking = false; # Tap to click disabled
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
      };

      # Spaces configuration
      spaces.spans-displays = false; # Displays have separate spaces

      # Login window
      loginwindow = {
        GuestEnabled = false; # Disable guest account
        DisableConsoleAccess = true; # Disable console login
      };

      # Accessibility (also disables animations system-wide)
      universalaccess = {
        reduceMotion = true; # Reduce motion system-wide
        reduceTransparency = true; # Reduce transparency effects
      };

      # Custom user preferences (for settings not directly exposed)
      CustomUserPreferences = {
        "com.apple.finder" = {
          DisableAllAnimations = true; # Disable all Finder animations
        };
        NSGlobalDomain = {
          AppleAccentColor = 6; # Pink
          AppleHighlightColor = "1.000000 0.749020 0.823529 Pink"; # Pink selection color
        };
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

  # CoreDNS configuration
  # Place Corefile in /etc
  environment.etc."coredns/Corefile".source = ./files/Corefile;

  # Run coredns as a system daemon
  launchd.daemons.coredns = {
    script = ''
      exec ${pkgs.coredns}/bin/coredns -conf /etc/coredns/Corefile
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/coredns.log";
      StandardErrorPath = "/var/log/coredns.log";
      EnvironmentVariables = {
        "GOMAXPROCS" = "2";
      };
    };
  };

  # Restart coredns after configuration changes
  system.activationScripts.postActivation.text = ''
    echo "Restarting coredns..."
    /bin/launchctl kickstart -k system/org.nixos.coredns 2>/dev/null || true
  '';

  # Configure Scroll Reverser to launch and reverse mouse only
  launchd.user.agents.configure-scroll-reverser = {
    script = ''
      # Set Scroll Reverser preferences
      /usr/bin/defaults write com.pilotmoon.scroll-reverser ReverseScrolling -bool true
      /usr/bin/defaults write com.pilotmoon.scroll-reverser ReverseMouseScrolling -bool true
      /usr/bin/defaults write com.pilotmoon.scroll-reverser ReverseTrackpad -bool false
      /usr/bin/defaults write com.pilotmoon.scroll-reverser ReverseTablet -bool false
      /usr/bin/defaults write com.pilotmoon.scroll-reverser StartAtLogin -bool true

      # Launch Scroll Reverser if not already running
      if ! pgrep -x "Scroll Reverser" > /dev/null; then
        open -a "Scroll Reverser"
      fi
    '';
    serviceConfig = {
      RunAtLoad = true;
      ProcessType = "Interactive";
    };
  };

  # Set wallpaper to solid color on login
  launchd.user.agents.set-wallpaper = {
    script = ''
      ${pkgs.swift}/bin/swift - <<'SWIFT'
      import Cocoa
      import AppKit

      extension NSColor {
          convenience init(hex: String) {
              let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
              var int: UInt64 = 0
              Scanner(string: hex).scanHexInt64(&int)
              let r = CGFloat((int >> 16) & 0xFF) / 255.0
              let g = CGFloat((int >> 8) & 0xFF) / 255.0
              let b = CGFloat(int & 0xFF) / 255.0
              self.init(red: r, green: g, blue: b, alpha: 1.0)
          }
      }

      let transparentImage = URL(fileURLWithPath: "/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane/Contents/Resources/DesktopPictures.prefPane/Contents/Resources/Transparent.tiff")
      let color = NSColor(hex: "13141C")
      let options: [NSWorkspace.DesktopImageOptionKey: Any] = [.fillColor: color]

      for screen in NSScreen.screens {
          try? NSWorkspace.shared.setDesktopImageURL(transparentImage, for: screen, options: options)
      }
      SWIFT
    '';
    serviceConfig = {
      RunAtLoad = true;
      ProcessType = "Interactive";
    };
  };

  # Security configuration
  security.pam.services.sudo_local.touchIdAuth = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=86400
    Defaults timestamp_type=tty
  '';

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
