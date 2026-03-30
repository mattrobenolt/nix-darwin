{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    installBatSyntax = true;
    package = pkgs.ghostty;

    settings = {
      font-family = "Hack Nerd Font Mono";
      font-size = 10;
      adjust-cell-height = "10%";

      cursor-style = "bar";
      cursor-style-blink = true;
      shell-integration-features = true;

      window-padding-x = 8;
      window-padding-y = 8;

      command = "/run/current-system/sw/bin/zsh";

      confirm-close-surface = true;

      window-save-state = "always";
      cursor-click-to-move = true;

      window-vsync = true;

      minimum-contrast = 1;

      unfocused-split-opacity = "0.8";

      palette = [
        "0=#000000"
        "1=#ff5555"
        "2=#50fa7b"
        "3=#f1fa8c"
        "4=#bd93f9"
        "5=#ff79c6"
        "6=#8be9fd"
        "7=#bbbbbb"
        "8=#555555"
        "9=#ff5555"
        "10=#50fa7b"
        "11=#f1fa8c"
        "12=#bd93f9"
        "13=#ff79c6"
        "14=#8be9fd"
        "15=#ffffff"
      ];
      background = "#191a24";
      foreground = "#f8f8f2";
      cursor-color = "#bbbbbb";
      selection-background = "#44475a";
      selection-foreground = "#ffffff";

      # macOS-style keybindings (using Super, which is physical Alt after swap)
      keybind = [
        # Tab management (like macOS Cmd+T, Cmd+W, Cmd+N)
        # After swap: physical Alt = Super key code
        "super+t=new_tab"
        "super+w=close_surface"
        "super+n=new_window"

        # Tab switching (like macOS Cmd+1, Cmd+2, etc.)
        "super+one=goto_tab:1"
        "super+two=goto_tab:2"
        "super+three=goto_tab:3"
        "super+four=goto_tab:4"
        "super+five=goto_tab:5"
        "super+six=goto_tab:6"
        "super+seven=goto_tab:7"
        "super+eight=goto_tab:8"
        "super+nine=goto_tab:9"

        # Navigate tabs (like macOS Cmd+Shift+[ and ])
        "super+shift+left_bracket=previous_tab"
        "super+shift+right_bracket=next_tab"

        # Splits (like iTerm2 Cmd+D and Cmd+Shift+D)
        "super+d=new_split:right"
        "super+shift+d=new_split:down"

        # Zoom/maximize split (like iTerm2 Cmd+Shift+Enter)
        "super+shift+enter=toggle_split_zoom"

        # Navigate splits with arrows (Cmd+Opt+arrows on macOS)
        # After swap: physical Alt+Super+arrows = Super+Alt+arrows
        "super+alt+up=goto_split:top"
        "super+alt+down=goto_split:bottom"
        "super+alt+left=goto_split:left"
        "super+alt+right=goto_split:right"

        # Navigate splits with vim keys (bonus, same binding)
        "super+alt+h=goto_split:left"
        "super+alt+l=goto_split:right"
        "super+alt+k=goto_split:top"
        "super+alt+j=goto_split:bottom"

        # Font size (like macOS Cmd+Plus, Cmd+Minus, Cmd+0)
        "super+equal=increase_font_size:1"
        "super+minus=decrease_font_size:1"
        "super+zero=reset_font_size"

        # Clear screen (like macOS Cmd+K)
        "super+k=clear_screen"

        # Copy/Paste (keep Ctrl+Shift as standard Linux fallback)
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"

        "super+p=toggle_command_palette"
      ];
    };
  };
}
