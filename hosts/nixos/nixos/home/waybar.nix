{ pkgs, ... }:
let
  sinkCycle = pkgs.writeShellScriptBin "sink-cycle" (builtins.readFile ./scripts/sink-cycle.sh);
in
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        modules-left = [ "hyprland/workspaces" ];
        modules-right = [
          "custom/sink"
          "pulseaudio"
          "network"
          "clock"
        ];

        "custom/sink" = {
          exec = "${sinkCycle}/bin/sink-cycle status";
          interval = 5;
          on-scroll-up = "${sinkCycle}/bin/sink-cycle next";
          on-scroll-down = "${sinkCycle}/bin/sink-cycle prev";
          on-click = "${sinkCycle}/bin/sink-cycle next";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{:%Y-%m-%d}";
        };

        pulseaudio = {
          format = "vol {volume}%";
          format-muted = "muted";
          on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
          on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };

        network = {
          format-ethernet = "eth {ipaddr}";
          format-disconnected = "offline";
        };
      };
    };
    style = ''
      * {
        font-family: monospace;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
      window#waybar {
        background: #1e1e2e;
        color: #cdd6f4;
      }
      #workspaces button {
        padding: 0 5px;
        color: #cdd6f4;
      }
      #workspaces button.active {
        color: #1e1e2e;
        background: #cdd6f4;
      }
      #clock, #pulseaudio, #network, #custom-sink {
        padding: 0 10px;
      }
    '';
  };
}
