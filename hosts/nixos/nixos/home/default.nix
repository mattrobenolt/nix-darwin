{
  # Shared NixOS layer (home-common.nix + linux package set) lives in
  # hosts/nixos/home.nix. The desktop is a pure terminal host with no
  # DE/WM; everything else comes from the shared config.
  imports = [ ../../home.nix ];

  home.stateVersion = "26.05";
}
