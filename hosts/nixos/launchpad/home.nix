{ lib, ... }:

{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix.
  imports = [ ../home.nix ];

  home.stateVersion = "26.05";

  programs.git = {
    # The shared config signs with matt's Mac key, which does not exist
    # here. The box gets its own signing key in the auth iteration.
    signing.signByDefault = lib.mkForce false;
  };
}
