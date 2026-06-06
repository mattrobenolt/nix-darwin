{ inputs, pkgs, ... }:
{
  imports = [
    inputs.hyprshell.homeModules.default
  ];

  programs.hyprshell = {
    enable = true;
    package = inputs.hyprshell.packages.${pkgs.stdenv.hostPlatform.system}.hyprshell;

    settings = {
      windows = {
        enable = true;

        overview = {
          enable = true;
          key = "space";
          modifier = "super";
          launcher = {
            max_items = 6;
          };
        };

        switch = {
          enable = true;
          modifier = "super";
        };
      };
    };
  };
}
