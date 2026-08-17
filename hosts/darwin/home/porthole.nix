{ inputs, ... }:

{
  # porthole daemon: URLs opened on remote hosts land in this Mac's
  # browser. Runs under launchd; declares one ssh RemoteForward per host
  # (names must match the Host aliases in ./ssh.nix). The client half
  # lives on launchpad (hosts/nixos/launchpad/home.nix).
  imports = [ inputs.porthole.homeModules.porthole-daemon ];

  programs.porthole = {
    enable = true;
    hosts = [ "launchpad" ];
    # The module's default package uses builtins.currentSystem, which does
    # not exist in pure (flake) eval. Pin the build.
    package = inputs.porthole.packages.aarch64-darwin.porthole;
  };
}
