{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      manager = {
        show_hidden = true;
      };

      plugin = {
        prepend_previewers = [
          {
            name = "*.md";
            run = "${pkgs.glow}/bin/glow";
          }
          {
            mime = "text/";
            run = "${pkgs.bat}/bin/bat";
          }
        ];

        append_previewers = [
          {
            name = "*";
            run = "${pkgs.hexyl}/bin/hexyl";
          }
        ];
      };
    };

    theme = {
      flavor = {
        use = "catppuccin-mocha";
      };
    };
  };
}
