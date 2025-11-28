{ pkgs, ... }:

{
  # Shared configuration across all machines (macOS and Linux)

  # Common CLI packages - tools you want everywhere
  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    vim
    neovim
    curl
    wget

    # Modern CLI replacements
    bat         # better cat
    eza         # better ls
    ripgrep     # better grep
    fd          # better find
    dust        # better du
    delta       # better git diff
    difftastic  # semantic diff

    # Shell enhancements
    zsh
    fish
    starship
    atuin
    direnv
    nix-direnv
    zoxide
    fzf

    # Development tools
    gh          # GitHub CLI
    lazygit
    jq
    jaq
    yq
    yj
    just

    # Languages
    go
    nodejs
    python3
    bun

    # Nix tools
    nil         # nix LSP
    nixd        # nix LSP
    nixfmt-rfc-style
    deadnix
    statix

    # Terminal multiplexers
    tmux
    zellij

    # Monitoring
    btop
    htop
    hwatch

    # Network tools
    socat
    mtr
    wrk
    grpcurl

    # File tools
    watch
    watchexec
    entr
    hexyl

    # Misc utilities
    fortune
    cowsay
    lolcat
    fastfetch
    terminal-notifier
  ];

  # Nix configuration
  # Disable for Determinate Nix on macOS, enable for standard Nix/NixOS
  nix.enable = false;  # Override this in NixOS hosts

  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # Shell integration
  programs.zsh.enable = true;
}
