{ pkgs, ... }:
{
  # hyprsunset - Blue light filter with time-based profiles

  # Config file for hyprsunset
  home.file.".config/hypr/hyprsunset.conf".text = ''
    max-gamma = 150

    # Daytime profile - no filter
    profile {
        time = 7:30
        identity = true
    }

    # Evening profile - warm temperature, slightly reduced gamma
    profile {
        time = 21:00
        temperature = 4500
        gamma = 0.9
    }
  '';

  # Run hyprsunset as systemd service
  systemd.user.services.hyprsunset = {
    Unit = {
      Description = "Hyprland blue light filter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
