_: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "300, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(f8f8f2)"; # Dracula foreground
          inner_color = "rgb(282a36)"; # Dracula background
          outer_color = "rgb(bd93f9)"; # Dracula purple
          outline_thickness = 2;
          placeholder_text = ''<span foreground="##6272a4">Password...</span>'';
          shadow_passes = 2;
        }
      ];

      label = [
        {
          # Time
          monitor = "";
          text = ''cmd[update:1000] echo "<b><big> $(date +"%H:%M") </big></b>"'';
          color = "rgb(f8f8f2)"; # Dracula foreground
          font_size = 64;
          font_family = "Hack Nerd Font Mono";
          position = "0, 16";
          halign = "center";
          valign = "center";
        }
        {
          # Date
          monitor = "";
          text = ''cmd[update:18000000] echo "<b> $(date +'%A, %B %-d') </b>"'';
          color = "rgb(f8f8f2)"; # Dracula foreground
          font_size = 24;
          font_family = "Hack Nerd Font Mono";
          position = "0, -16";
          halign = "center";
          valign = "center";
        }
        {
          # User
          monitor = "";
          text = "    $USER";
          color = "rgb(f8f8f2)"; # Dracula foreground
          font_size = 18;
          font_family = "Hack Nerd Font Mono";
          position = "0, -130";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
