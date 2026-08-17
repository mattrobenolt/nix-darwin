{ pkgs, lib, ... }:

{
  # Shared configuration across all machines (macOS and Linux)

  # Common packages across all machines
  # Currently empty - move packages here from host configs as you identify what's truly shared
  environment.systemPackages = with pkgs; [
    bat
    curl
    direnv
    eza
    fastfetch
    fd
    git
    htop
    jq
    nix-direnv
    pkg-config
    ripgrep
    rtk
    starship
    tmux
    vim
    wget
    zellij
    zsh
  ];

  # Nix configuration
  # Disable for Determinate Nix on macOS, enable for standard Nix/NixOS
  nix.enable = false; # Override this in NixOS hosts

  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # nix-darwin's generated HTML manual currently lags nixos-render-docs.
  # Keep manpages, skip the fragile HTML manual/darwin-help package.
  documentation.doc.enable = false;

  # The bundled uninstaller builds its own default darwin system, including
  # the same broken HTML manual. Prefer `nix run nix-darwin#darwin-uninstaller`
  # if this machine ever needs uninstalling.
  system.tools.darwin-uninstaller.enable = false;

  # Shell integration
  programs.zsh.enable = true;
  # Note: User's default shell is managed by home-manager (see home/zsh.nix)

  # Minimal user definition for nix-darwin (home-manager's nix-darwin integration needs this)
  # Only define on Darwin - NixOS hosts should define users in their host config
  users.users.matt = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    uid = 501; # Standard first user UID on macOS - override in host config if different
  };

  # Automatic garbage collection (Darwin only, manual launchd daemon since nix.enable = false)
  # Based on nix-darwin's nix-gc module but without the nix.enable requirement
  launchd.daemons.nix-gc = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    script = ''
      exec ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 30d
    '';
    serviceConfig = {
      StartCalendarInterval = [
        {
          Weekday = 0; # Sunday
          Hour = 3;
          Minute = 15;
        }
      ];
      RunAtLoad = false;
    };
  };
}
