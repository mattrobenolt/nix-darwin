{ config, ... }:

{
  # Nix's user config. Nix reads /etc/nix/nix.conf first and this file second,
  # so values here win. That order is the whole point: Determinate writes
  # `netrc-file = /nix/var/determinate/netrc` in nix.conf *after* its
  # `!include nix.custom.conf` line, so the same setting declared in
  # nix.custom.conf (see hosts/darwin/work.nix) is dead — later wins.
  #
  # Point netrc-file at Rex's 0600 package-repository netrc so `just update`,
  # `just check`, and a bare `nix flake update rex` can fetch the private
  # preview flake. Path only, never the token. Determinate's merged netrc is
  # empty, so replacing it costs nothing.
  xdg.configFile."nix/nix.conf".text = ''
    netrc-file = ${config.home.homeDirectory}/.config/rex/packages.netrc
  '';
}
