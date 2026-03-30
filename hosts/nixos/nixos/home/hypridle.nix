_: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # Lock if not already locked
        before_sleep_cmd = "loginctl lock-session"; # Lock before suspend
        after_sleep_cmd = "hyprctl dispatch dpms on"; # Turn on display after suspend
      };

      listener = [
        {
          timeout = 300; # 10 minutes
          on-timeout = "loginctl lock-session"; # Lock screen
        }
        {
          timeout = 330; # 10.5 minutes
          on-timeout = "hyprctl dispatch dpms off"; # Turn off display
          on-resume = "hyprctl dispatch dpms on"; # Turn on display
        }
      ];
    };
  };
}
