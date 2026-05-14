{ inputs, ... }:

{
  # Shared home-manager configuration across all machines

  imports = [
    inputs.mattware.homeModules.hunk
    ./common/git.nix
    ./common/hunk.nix
    ./common/starship.nix
    ./common/zsh.nix
    ./common/atuin.nix
    ./common/bat.nix
    ./common/delta.nix
    ./common/direnv.nix
    ./common/btop.nix
    ./common/eza.nix
    ./common/htop.nix
    ./common/neovim.nix
    ./common/yazi.nix
    ./common/zellij.nix
    ./common/zoxide.nix
    ./common/qmd.nix
    ./common/npm.nix
  ];
}
