{ modulesPath, ... }:

{
  # EC2/Nitro guest support. This is the same module the official NixOS AMIs
  # are built from, so our rebuild matches the booted image:
  #   - root filesystem on the "nixos" label, grown to fill the EBS volume
  #   - bootloader suitable for Nitro (EFI on aarch64)
  #   - serial console output
  #   - root SSH key fetched from EC2 metadata (the EC2 keypair works at boot)
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # The instance is pure EBS; no instance store to manage.
  services.fstrim.enable = true;

  # Compressed swap in RAM. Cheap insurance for memory-hungry builds.
  zramSwap.enable = true;
}
