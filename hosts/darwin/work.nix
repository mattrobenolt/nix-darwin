{
  pkgs,
  lib,
  mattware,
  llm-agents,
  ...
}:

let
  nixSettings = import ../../common/nix-settings.nix;
  piWrapper = pkgs.writeShellScriptBin "pi" ''
    set -euo pipefail

    PI_HOME="$HOME/.pi/agent"
    PI_BIN="$PI_HOME/node_modules/.bin/pi"
    PI_PROFILE_SCRIPT="$PI_HOME/scripts/pi-profile"

    if [ ! -x "$PI_BIN" ]; then
      echo "pi is not installed in $PI_HOME" >&2
      echo "Run: cd $PI_HOME && npm install" >&2
      exit 1
    fi

    PI_PROFILE=work PI_BIN="$PI_BIN" exec "$PI_PROFILE_SCRIPT" "$@"
  '';

  piPersonalWrapper = pkgs.writeShellScriptBin "pi-personal" ''
    set -euo pipefail

    PI_HOME="$HOME/.pi/agent"
    PI_BIN="$PI_HOME/node_modules/.bin/pi"
    PI_PROFILE_SCRIPT="$PI_HOME/scripts/pi-profile"

    if [ ! -x "$PI_BIN" ]; then
      echo "pi is not installed in $PI_HOME" >&2
      echo "Run: cd $PI_HOME && npm install" >&2
      exit 1
    fi

    PI_PROFILE=personal PI_BIN="$PI_BIN" exec "$PI_PROFILE_SCRIPT" "$@"
  '';

in

{
  # Work MacBook Pro specific configuration

  imports = [
    ./disable-bloat.nix
  ];

  # 1Password GUI - installs to /Applications
  # programs._1password-gui.enable = true;

  # Package overrides
  nixpkgs.overlays = [
    # Use custom packaging from personal nixpkgs fork (matt_go, zlint, etc.)
    mattware.overlays.default

    (_final: prev: {
      # coredns build is broken in nixpkgs-unstable (bad patches), skip patches and tests
      coredns = prev.coredns.overrideAttrs (_oldAttrs: {
        postPatch = ""; # Skip broken patches
        doCheck = false; # Skip tests
      });
    })
  ];

  environment.systemPackages =
    with pkgs;
    [
      age
      asciinema
      atuin
      awscli2
      btop
      bun
      clang
      coredns
      deadnix
      delta
      difftastic
      dust
      entr
      exiftool
      fzf
      gh
      glow
      gnutar
      go-bin_1_26
      google-cloud-sdk
      graphviz
      hexyl
      hwatch
      hyperfine
      jinja2-cli
      just
      kustomize
      lazygit
      luarocks
      mariadb.client
      mtr
      nghttp2
      nixd
      nixfmt
      nixfmt-tree
      nodejs
      procs
      postgresql_18
      pstree
      pwgen
      python3
      rustup
      scc
      sentry-cli
      shellcheck
      socat
      statix
      swift
      swift-format
      timg
      uv
      watch
      watchexec
      weechat
      wrk
      yazi
      yj
      yq
      zoxide
      zig_0_15
      zls_0_15
    ]
    ++ (with llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      amp
      claude-code
      codex
    ])
    ++ [
      piWrapper
      piPersonalWrapper
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
      "mattrobenolt/stuff"
      "sst/tap"
    ];

    brews = [
      "sst/tap/opencode"
      "gemini-cli"
      "syncthing"
      "tailscale"
      "tracy"
      "mole"
    ];

    casks = [
      "1password-cli"
      "1password"
      "appify"
      "audacity"
      "chatgpt"
      "claude"
      "discord"
      "helium-browser"
      "imageoptim"
      "inbox"
      "istat-menus"
      "notion"
      "obsidian"
      "opencode-desktop"
      "orbstack"
      "plexamp"
      "proton-pass"
      "raycast"
      "scroll-reverser"
      "session-manager-plugin"
      "slack"
      "telegram-desktop"
      "utm"
      "vanilla"
    ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    hack-font
    inter
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

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
        mru-spaces = true; # Don't auto-rearrange spaces
        show-process-indicators = true; # Show dots under running apps
        minimize-to-application = false; # Minimize into app icon
        # Animation disabling
        autohide-delay = 0.0; # No delay before dock appears
        autohide-time-modifier = 0.0; # Instant dock show/hide
        expose-animation-duration = 0.0; # Instant mission control
        launchanim = true; # Disable app launch bouncing
        mineffect = "genie"; # Faster minimize effect
      };

      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = false;
        FXPreferredViewStyle = "clmv"; # Column view
        # Behavior improvements
        FXEnableExtensionChangeWarning = false; # No warning when changing extensions
        FXDefaultSearchScope = "SCcf";
        QuitMenuItem = true;
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
        NSDocumentSaveNewDocumentsToCloud = false;
        AppleICUForce24HourTime = true;
      };

      menuExtraClock = {
        Show24Hour = true;
        IsAnalog = true;
      };

      controlcenter = {
        NowPlaying = false;
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
        reduceMotion = false; # Reduce motion system-wide
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

      WindowManager = {
        GloballyEnabled = false;
        EnableTiledWindowMargins = false;
        StandardHideWidgets = true;
        EnableStandardClickToShowDesktop = false;
      };

      LaunchServices.LSQuarantine = false;
    }; # end system.defaults
  }; # end system

  # Networking configuration
  networking = {
    computerName = "Matt's MacBook Pro";
    hostName = "Matts-MacBook-Pro";
    localHostName = "Matts-MacBook-Pro";
    knownNetworkServices = [ "Wi-Fi" ];
    wakeOnLan.enable = false;

    # Point to local coredns instance
    dns = [ "127.0.0.1" ];

    # DNS search domains (Tailscale MagicDNS + mDNS)
    search = [
      "tail45c3.ts.net"
      "local"
    ];
  };

  # Environment configuration
  environment.etc = {
    # Nix daemon custom configuration
    "nix/nix.custom.conf".text = ''
      download-buffer-size = ${nixSettings.downloadBufferSize}
      extra-trusted-substituters = ${lib.concatStringsSep " " nixSettings.substituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " nixSettings.trustedPublicKeys}
      trusted-users = ${lib.concatStringsSep " " nixSettings.trustedUsers}
    '';

    # CoreDNS configuration - Place Corefile in /etc
    # Use .text instead of .source so nix creates a dedicated store derivation
    # that's properly tracked in the closure and won't get GC'd.
    "coredns/Corefile".text = builtins.readFile ./files/Corefile;
  };

  # LaunchD services
  launchd = {
    # DNS enforcement daemon
    # Ensures DNS stays pointed to coredns even when DHCP tries to override
    daemons.enforce-dns = {
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

    # Run coredns as a system daemon
    daemons.coredns = {
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

    user.agents = {
      # Configure Scroll Reverser to launch and reverse mouse only
      configure-scroll-reverser = {
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
      set-wallpaper = {
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
          let color = NSColor(hex: "191A24")
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

      pi-memory-curate = {
        serviceConfig =
          let
            pi = piWrapper;
            qmdVersion = "2.0.1";
            qmd = pkgs.writeShellScriptBin "qmd" ''
              QMD_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/qmd/${qmdVersion}"
              if [ ! -d "$QMD_DIR/node_modules" ]; then
                mkdir -p "$QMD_DIR"
                (cd "$QMD_DIR" && ${pkgs.bun}/bin/bun add --trust @tobilu/qmd@${qmdVersion})
              fi
              exec "$QMD_DIR/node_modules/.bin/qmd" "$@"
            '';
          in
          {
            Label = "com.mattrobenolt.pi-memory-curate";
            ProgramArguments = [
              "${pkgs.nushell}/bin/nu"
              "/Users/matt/.pi/agent/skills/curate-memory/run.sh"
            ];
            EnvironmentVariables = {
              HOME = "/Users/matt";
              PATH = "${pi}/bin:${qmd}/bin:${pkgs.nushell}/bin:${pkgs.bun}/bin:${pkgs.nodejs}/bin:/usr/bin:/bin";
            };
            # Run hourly — script decides whether to actually curate based on activity
            StartInterval = 3600;
            StandardOutPath = "/Users/matt/.pi/agent/memory/curation.log";
            StandardErrorPath = "/Users/matt/.pi/agent/memory/curation.log";
            RunAtLoad = false;
          };
      };
    }; # user.agents
  };

  # Restart services after configuration changes
  system.activationScripts.postActivation.text = ''
    echo "Restarting nix daemon..."
    /bin/launchctl kickstart -k system/systems.determinate.nix-daemon 2>/dev/null || true

    echo "Restarting coredns..."
    /bin/launchctl kickstart -k system/org.nixos.coredns 2>/dev/null || true

    echo "Clearing icon cache..."
    /usr/bin/find /private/var/folders/ -name com.apple.dock.iconcache -exec rm -f {} \; 2>/dev/null || true
  '';

  # Security configuration
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=86400
    Defaults timestamp_type=tty
  '';

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
