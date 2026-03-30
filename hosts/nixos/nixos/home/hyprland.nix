_: {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";

      monitor = ",preferred,auto,auto";

      exec-once = [
        "waybar"
        "wl-clip-persist --clipboard regular"
        "1password --silent"
      ];

      bind = [
        # App launching (like macOS Cmd+Space, Cmd+Return)
        # Launcher handled by hyprshell overview (Alt+Space)
        #"$mod, Return, exec, $terminal +new-window"

        # Window management (macOS-style)
        "$mod, Q, killactive" # Cmd+Q to quit/close window
        #"$mod, W, killactive" # Also Cmd+W (more macOS-like for closing)
        #"$mod, F, fullscreen, 0" # Cmd+Ctrl+F for fullscreen on macOS

        # Focus movement (like macOS window switching)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Move windows
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Workspace switching (like macOS Spaces with Ctrl+1,2,3...)
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Move window to workspace (like macOS Cmd+Shift+1,2,3...)
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        # Window switcher handled by hyprshell module (Alt+Tab)
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        "col.active_border" = "rgb(50fa7b) rgb(bd93f9) 45deg";
        "col.inactive_border" = "rgb(44475a)";
      };

      decoration = {
        rounding = 0;
        shadow.enabled = false;
        blur.enabled = false;
      };

      animations.enabled = false;

      input = {
        follow_mouse = 1;
        accel_profile = "adaptive";
        sensitivity = -0.8;

        repeat_rate = 65;
        repeat_delay = 225;

        kb_options = "altwin:swap_alt_win";
      };

      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "NIXOS_OZONE_WL,1"
      ];

      misc = {
        disable_hyprland_logo = true;
        background_color = "rgb(191a24)";
      };
    };
  };
}
