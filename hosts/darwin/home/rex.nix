{ config, lib, ... }:

{
  # Rex (beta, superlogical.com) — the app embeds its own Rex server and
  # Ghostty's renderer. Keys and Lua are declarative via xdg.configFile
  # (reload with `rex config reload`); appearance has no config-file
  # surface at all — it lives in com.superlogical.rex defaults — so the
  # activation at the bottom owns the look, mapping the ghostty config
  # onto Rex key by key.
  xdg.configFile = {
    "rex/init.lua".text = ''
      -- Managed by home-manager (hosts/darwin/home/rex.nix).
      -- Ref: https://www.superlogical.com/rex/docs/reference/lua.md

      -- shift+enter inserts a newline without running the line.
      -- Matches ghostty: keybind = shift+enter=text:\n
      rex.bind("shift+enter", function(ctx, ev)
        rex.block.call("com.superlogical.terminal", "write", { data = "\n" })
        return true
      end)
    '';

    # rex.on only works under `rex do`, never in init.lua, so tab labels
    # need this kept running in a spare block: rex do labels.lua --all
    "rex/labels.lua".text = ''
      -- Label each terminal with its working directory.
      rex.on("terminal.pwd_changed", function(ctx, ev)
        local dir = ev.pwd:match("([^/]+)/?$")
        rex.session.set_block_label{
          block_id = ctx.block_id,
          label    = dir,
        }
      end)
    '';

    # The exact theme JSON Rex's Ghostty importer wrote from
    # ghostty/Dracula (captured 2026-10-15, byte-identical object). The
    # activation feeds these bytes to Workspace.customThemes. Colors are
    # srgb floats; the readable hex source of truth is ghostty/Dracula,
    # which produced them.
    "rex/dracula-theme.json".text = ''
      [
        {
          "id": "custom-CC573C07-C54A-4A4B-89E9-5862B9BEF33D",
          "name": "Dracula",
          "appearance": "dark",
          "palette": {
            "selectionForeground": {
              "colorSpace": "srgb",
              "red": 1,
              "green": 1,
              "blue": 1,
              "alpha": 1
            },
            "paletteBase": {},
            "paletteHarmonious": true,
            "selectionBackground": {
              "colorSpace": "srgb",
              "red": 0.26666666666666666,
              "green": 0.2784313725490196,
              "blue": 0.35294117647058826,
              "alpha": 1
            },
            "cursor": {
              "colorSpace": "srgb",
              "red": 0.7333333333333333,
              "green": 0.7333333333333333,
              "blue": 0.7333333333333333,
              "alpha": 1
            },
            "ansi": [
              {
                "colorSpace": "srgb",
                "red": 0,
                "green": 0,
                "blue": 0,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 1,
                "green": 0.3333333333333333,
                "blue": 0.3333333333333333,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.3137254901960784,
                "green": 0.9803921568627451,
                "blue": 0.4823529411764706,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.9450980392156862,
                "green": 0.9803921568627451,
                "blue": 0.5490196078431373,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.7411764705882353,
                "green": 0.5764705882352941,
                "blue": 0.9764705882352941,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 1,
                "green": 0.4745098039215686,
                "blue": 0.7764705882352941,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.5450980392156862,
                "green": 0.9137254901960784,
                "blue": 0.9921568627450981,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.7333333333333333,
                "green": 0.7333333333333333,
                "blue": 0.7333333333333333,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.3333333333333333,
                "green": 0.3333333333333333,
                "blue": 0.3333333333333333,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 1,
                "green": 0.3333333333333333,
                "blue": 0.3333333333333333,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.3137254901960784,
                "green": 0.9803921568627451,
                "blue": 0.4823529411764706,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.9450980392156862,
                "green": 0.9803921568627451,
                "blue": 0.5490196078431373,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.7411764705882353,
                "green": 0.5764705882352941,
                "blue": 0.9764705882352941,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 1,
                "green": 0.4745098039215686,
                "blue": 0.7764705882352941,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 0.5450980392156862,
                "green": 0.9137254901960784,
                "blue": 0.9921568627450981,
                "alpha": 1
              },
              {
                "colorSpace": "srgb",
                "red": 1,
                "green": 1,
                "blue": 1,
                "alpha": 1
              }
            ],
            "paletteGenerate": true,
            "foreground": {
              "colorSpace": "srgb",
              "red": 0.9725490196078431,
              "green": 0.9725490196078431,
              "blue": 0.9490196078431372,
              "alpha": 1
            },
            "cursorText": {
              "colorSpace": "srgb",
              "red": 0.09803921568627451,
              "green": 0.10196078431372549,
              "blue": 0.1411764705882353,
              "alpha": 1
            },
            "paletteOverrides": {},
            "background": {
              "colorSpace": "srgb",
              "red": 0.09803921568627451,
              "green": 0.10196078431372549,
              "blue": 0.1411764705882353,
              "alpha": 1
            }
          },
          "source": {
            "ghosttyFile": {
              "fileName": "Dracula"
            }
          },
          "createdAt": 813826763.611004
        }
      ]
    '';
  };

  # Rex's Ghostty migration only searches ~/Library/Application
  # Support/com.mitchellh.ghostty (it misses the XDG path), so make our
  # home-managed config visible there. Ghostty itself never reads this
  # copy (XDG wins in its search order, identical content anyway).
  home.file = {
    "Library/Application Support/com.mitchellh.ghostty/config".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty/config";
    # `config-file = ./Dracula` resolves relative to the config's location,
    # so the theme needs to resolve there too.
    "Library/Application Support/com.mitchellh.ghostty/Dracula".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty/Dracula";
  };

  # Appearance. Rex keeps looks in com.superlogical.rex defaults, written
  # by its Settings UI; there is no config file for them. defaults write
  # is the only declarative route, including for keys the UI never
  # exposes (terminalCellHeightPercent). Managed keys revert UI changes
  # on the next `just apply`.
  home.activation.rexDefaults = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # Activation runs without /usr/bin on PATH, so the macOS tools get
    # absolute paths.
    _rex() { /usr/bin/defaults write com.superlogical.rex "$@"; }
    _rex_hex() { /usr/bin/od -An -v -tx1 < "$1" | /usr/bin/tr -d ' \n'; }

    # Theme imported from ghostty/Dracula.
    _rex Workspace.darkThemeID -string custom-CC573C07-C54A-4A4B-89E9-5862B9BEF33D
    _rex Workspace.customThemes -data "$(_rex_hex ${config.xdg.configHome}/rex/dracula-theme.json)"

    # ghostty config equivalents.
    _rex Workspace.terminalFontName -string "Hack Nerd Font Mono"  # font-family
    _rex Workspace.terminalFontPointSize -int 13                   # font-size
    _rex Workspace.terminalCellHeightPercent -int 10               # adjust-cell-height = 10%
    _rex Workspace.terminalCursorStyle -string beam                # cursor-style = bar
    _rex Workspace.terminalOptionKeyBehavior -string left          # macos-option-as-alt = left
    _rex Workspace.terminalImproveTextContrast -bool false         # minimum-contrast = 1
  '';
}
