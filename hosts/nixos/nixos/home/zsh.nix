{ osConfig, ... }:

{
  programs.zsh.shellAliases = {
    nixos-update = "sudo nixos-rebuild switch --flake ~/.config/nixos#${osConfig.networking.hostName}";
  };
}
