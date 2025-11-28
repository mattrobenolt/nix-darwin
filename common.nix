{ pkgs, ... }:

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
    neovim
    nix-direnv
    pkg-config
    ripgrep
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

  # Shell integration
  programs.zsh.enable = true;

  # Default shell for user
  users.users.matt.shell = pkgs.zsh;
}
