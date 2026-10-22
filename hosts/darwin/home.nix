{ ... }:

{
  imports = [
    # herdr (binary installed in work.nix) — per-host, not in home-common:
    # the nixos desktop runs no herdr.
    ../../common/herdr.nix
    ../../common/herdr-plugins.nix
    ../../common/herdr-plugin-tab-smart-rename.nix
    ./home/ghostty.nix
    ./home/git.nix
    ./home/lazygit.nix
    ./home/nix.nix
    ./home/porthole.nix
    ./home/rex.nix
    ./home/ssh.nix
    ./home/zsh.nix
  ];
}
