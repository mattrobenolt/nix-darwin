{ osConfig, ... }:

{
  programs.zsh.shellAliases = {
    nixos-update = "sudo nixos-rebuild switch --flake ~/.config/nix-darwin#${osConfig.networking.hostName}";
  };
}
