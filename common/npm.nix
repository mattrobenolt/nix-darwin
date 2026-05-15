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
  home = {
    packages = [ pnpm ];

    sessionVariables = {
      NPM_CONFIG_USERCONFIG = "${config.home.homeDirectory}/.config/npm/npmrc";
      NPM_CONFIG_GLOBALCONFIG = "${config.home.homeDirectory}/.config/npm/global-npmrc";
    };

    file = {
      ".config/npm/global-npmrc".text = ''
        @planetscale:registry=https://registry.npmjs.org/
        allow-git=none
        min-release-age=3
        ignore-scripts=true
      '';

      ".config/pnpm/rc".text = ''
        allow-git=none
        min-release-age=3
        ignore-scripts=true
      '';
    };
  };
}
