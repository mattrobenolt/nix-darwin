{
  downloadBufferSize = "128M";
  substituters = [
    "https://mattrobenolt.cachix.org"
    "https://cache.numtide.com"
    "https://nix-community.cachix.org"
    "https://baskingspot.cachix.org"
  ];
  trustedPublicKeys = [
    "mattrobenolt.cachix.org-1:sn1IDSC4OxQvWaOVD4RRcqyKlket5wgb11nd1QII6i8="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "baskingspot.cachix.org-1:4KDZc1xfJdL8VGAOZo1SkOgZlqMNH+thBzux9J66EjU="
  ];
  trustedUsers = [
    "root"
    "matt"
  ];
}
