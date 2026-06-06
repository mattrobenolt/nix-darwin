{ inputs, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    configType = "lua";

    extraConfig = ''
      local mod = "SUPER"
      local terminal = "ghostty"
      local hyprshell = "${inputs.hyprshell.packages.${pkgs.stdenv.hostPlatform.system}.hyprshell}/bin/hyprshell"

      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

      hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
        hl.exec_cmd("wl-clip-persist --clipboard regular")
        hl.exec_cmd("1password --silent")
      end)

      hl.config({
        general = {
          gaps_in = 0,
          gaps_out = 0,
          border_size = 1,
          col = {
            active_border = {
              colors = { "rgb(50fa7b)", "rgb(bd93f9)" },
              angle = 45,
            },
            inactive_border = "rgb(44475a)",
          },
        },

        decoration = {
          rounding = 0,
          shadow = { enabled = false },
          blur = { enabled = false },
        },

        animations = { enabled = false },

        input = {
          follow_mouse = 1,
          accel_profile = "adaptive",
          sensitivity = -0.8,
          repeat_rate = 65,
          repeat_delay = 225,
          kb_options = "altwin:swap_alt_win",
        },

        env = {
          "LIBVA_DRIVER_NAME,nvidia",
          "XDG_SESSION_TYPE,wayland",
          "GBM_BACKEND,nvidia-drm",
          "__GLX_VENDOR_LIBRARY_NAME,nvidia",
          "NIXOS_OZONE_WL,1",
        },

        misc = {
          disable_hyprland_logo = true,
          background_color = "rgb(191a24)",
        },
      })

      hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
      hl.bind(mod .. " + Space", hl.dsp.exec_cmd(hyprshell .. " socat '\"OpenOverview\"'"))
      hl.bind(mod .. " + Q", hl.dsp.window.close())

      hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
      hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))
      hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
      hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))

      hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
      hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
      hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
      hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

      for i = 1, 9 do
        local workspace = tostring(i)
        hl.bind(mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
        hl.bind(mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
      end

      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
    '';
  };
}
