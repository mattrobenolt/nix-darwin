{ ... }:

{
  # Shared home-manager configuration across all machines

  imports = [
    ./common/git.nix
    ./common/starship.nix
    ./common/zsh.nix
    ./common/atuin.nix
    ./common/bat.nix
    ./common/delta.nix
    ./common/direnv.nix
    ./common/eza.nix
    ./common/neovim.nix
    ./common/zoxide.nix
  ];
}
