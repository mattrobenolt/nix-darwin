{ ... }:

{
  # Shared home-manager configuration across all machines

  imports = [
    ./common/git.nix
    ./common/starship.nix
  ];
}
