{ lib, ... }:

{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix.
  imports = [ ../home.nix ];

  home.stateVersion = "26.05";

  # Canonical ignore set for the pi-agent syncthing folder. The folder is
  # created by syncthing itself on first share; this symlink pre-exists so
  # the ignores are in effect before the first pull. The Mac side symlinks
  # the same file from this repo checkout.
  home.file.".pi/agent/.stignore".source = ./files/stignore-pi-agent;

  programs.git = {
    # The shared config signs with matt's Mac key, which does not exist
    # here. The box gets its own signing key in the auth iteration.
    signing.signByDefault = lib.mkForce false;
  };
}
