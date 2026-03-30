{ inputs, pkgs, ... }:
{
  imports = [
    inputs.hyprshell.homeModules.hyprshell
  ];

  programs.hyprshell = {
    enable = true;
    package = inputs.hyprshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      windows = {
        enable = true; # Must enable windows to use switch and overview

        # Window switcher (Alt+Tab)
        switch = {
          enable = true;
          modifier = "super"; # Alt key (after swap) triggers the switcher
        };

        # App launcher + window overview (Alt+Space like macOS Cmd+Space)
        overview = {
          enable = true;
          key = "space"; # Space key
          modifier = "super"; # Physical Alt (sends Super after swap)
          launcher = {
            max_items = 3; # Show up to 8 launcher items
          };
        };
      };
    };
  };
}
