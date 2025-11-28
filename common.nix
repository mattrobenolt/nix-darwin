{ pkgs, ... }:

{
  # Shared configuration across all machines (macOS and Linux)

  # Common packages across all machines
  # Currently empty - move packages here from host configs as you identify what's truly shared
  environment.systemPackages = with pkgs; [
    # Add shared packages here
  ];

  # Nix configuration
  # Disable for Determinate Nix on macOS, enable for standard Nix/NixOS
  nix.enable = false;  # Override this in NixOS hosts

  # Allow unfree packages (VS Code, etc.)
  nixpkgs.config.allowUnfree = true;

  # Shell integration
  programs.zsh.enable = true;
}
