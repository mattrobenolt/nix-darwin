{ pkgs, config, ... }:

let
  pnpm = pkgs.symlinkJoin {
    name = "pnpm";
    paths = [ pkgs.pnpm ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pnpm \
        --set XDG_CONFIG_HOME "${config.home.homeDirectory}/.config"
    '';
  };
in

{
  home.packages = [ pnpm ];

  home.file.".npmrc".text = ''
    @planetscale:registry=https://registry.npmjs.org/
    allow-git=none
    min-release-age=3
    ignore-scripts=true
  '';

  home.file.".config/pnpm/rc".text = ''
    allow-git=none
    min-release-age=3
    ignore-scripts=true
  '';
}
