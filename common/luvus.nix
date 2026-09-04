{
  pkgs,
  lib,
  ...
}:

let
  # Both files below are delivered by an activation COPY, not home.file.
  #
  # 1. The theme MUST be a real file: luvus's theme loader (src/theme/
  #    registry.rs, load_from) filters the themes dir with
  #    `entry.file_type().is_file()` — readdir metadata does NOT follow
  #    symlinks, so a home-manager symlink is silently skipped ("reloaded 18
  #    themes", no error). Upstream: RizRiyz/luvus#195.
  # 2. The config MUST NOT be home.file either, for a different reason:
  #    luvus REWRITES config.json at runtime (Settings writes, `theme use`,
  #    and the fallback persist when the selected theme is missing — an
  #    atomic rename that replaces the symlink with a real file). With
  #    home.file, the next activation then has a real-file collision; the
  #    first one succeeds by moving it to config.json.backup, but every
  #    later one hard-fails with "Existing file ... would be clobbered by
  #    backing up" because the .backup lingers. This exact failure bricked
  #    `just apply` on 2026-08-30 after luvus persisted a theme fallback.
  #    The copy has no collision path: activation always converges, and any
  #    runtime write simply reverts on the next rebuild — the intended
  #    posture (same as herdr's config.toml, minus the symlink).
  #
  # NEVER edit luvus settings from the UI — change them here and
  # `luvus server restart`. A UI edit (including the Settings → Theme
  # remove action) also mutates config.json and deletes theme files; the
  # next activation restores both.
  #
  # Do NOT `luvus theme install` the dracula-custom id from elsewhere —
  # the activation below restores this file on every rebuild.
  themeToml = pkgs.writeText "dracula-custom.toml" ''
    schema = 1
    id = "dracula-custom"
    display_name = "Dracula Custom"
    description = "dracula with matt's darker #191a24 background"
    author = "matt"
    version = "1.0.0"
    requires_luvus = ">=0.12.0"
    appearance = "dark"

    [colors]
    crust = "#0b0b11"
    mantle = "#191a24"
    base = "#242635"
    surface0 = "#12121a"
    surface1 = "#2d2f40"
    overlay0 = "#6272a4"
    overlay1 = "#828cb4"
    subtext0 = "#a0a4c0"
    subtext1 = "#cccee0"
    text = "#f8f8f2"
    accent = "#bd93f9"
    sel_bg = "#44475a"
    border = "#44475a"
    border_focus = "#6272a4"
    green = "#50fa7b"
    mint = "#8be9fd"
    amber = "#ffb86c"
    coral = "#ff5555"
  '';

  # Canonicalized from the Mac's config (the actively used host).
  # Launchpad's copy had diverged to fresh-install defaults on three keys
  # (prefix ctrl+space, sound_style retro, sidebars null) — not choices.
  # Config changes load on server start: `luvus server restart` picks them
  # up (session state survives in session.json, which stays runtime-owned).
  configJson = pkgs.writeText "luvus-config.json" ''
    {
      "version": 2,
      "theme": "dracula-custom",
      "language": "en",
      "shell": "default",
      "sidebar_width": 26,
      "sidebars": {
        "left": {
          "visible": true,
          "width": 26,
          "docks": [
            "workspaces",
            "agents"
          ]
        },
        "right": {
          "visible": false,
          "width": 26,
          "docks": []
        },
        "files_side": "left"
      },
      "layout": {
        "col_gap": 1,
        "row_gap": 0,
        "show_titles": true,
        "pane_title_path": false,
        "agent_title": false,
        "resume_in_new_workspace": true,
        "new_pane_to_workspace_root": false,
        "file_open": "readonly",
        "file_click": "preview",
        "scrollback_bytes": 10485760,
        "files_show_hidden": true,
        "diff_layout": "auto",
        "diff_wrap": false,
        "diff_context_lines": 3,
        "diff_show_line_numbers": true,
        "diff_marker_style": "symbols",
        "diff_color_mode": "theme",
        "diff_live_refresh": true,
        "mobile_width": 64,
        "shift_enter": "esc-cr"
      },
      "notifications": {
        "sound_style": "soft",
        "sound_on_done": false,
        "sound_on_blocked": false
      },
      "check_updates": true,
      "resume_launch_flags": false,
      "keybindings": {},
      "prefix": "ctrl+b",
      "mission_pricing": {},
      "mission_budget": null,
      "docks_off": [],
      "bars": {
        "top_right": [],
        "bottom_right": [
          "core:runtime-status"
        ],
        "off": []
      }
    }
  '';
in
{
  # luvus (luvus.dev) — agent mission-control terminal, from the upstream
  # flake input via the luvusOverlay in flake.nix (tracks main; bump the
  # input with `just update`). Their packaging wraps git/gh/ssh/procps
  # into the binary's PATH, so nothing extra is needed on any host.
  # `luvus update` never overwrites a nix-installed binary.
  #
  # Imported explicitly by hosts/darwin/home.nix and launchpad's home.nix —
  # NOT via home-common.nix, because only those two hosts apply the
  # luvusOverlay that provides pkgs.luvus.
  home.packages = [ pkgs.luvus ];

  # Theme role notes (luvus src/ui/theme.rs + rendering): mantle = pane
  # background and tab bar, crust = status bar (and fg on accent chips),
  # base = sidebar, surface0 = resting seams/inactive tabs, surface1 =
  # hover/raised elements. Those five rescale around matt's ghostty bg
  # (#191a24) with the same absolute offsets the built-in dracula uses.
  # overlay0/overlay1 (separators, tree connectors, dim labels, status
  # indicators) follow herdr's dracula instead of luvus's: herdr paints
  # that tier with the dracula comment blue (#6272a4) and a lighter blue
  # (#828cb4), which is the "more blue in the text" look — luvus's own
  # dracula uses a flat grey (#565869) there. Everything else is a named
  # dracula constant kept byte-identical. Ghostty-only changes
  # (pure-black ANSI 0, #bbbbbb/#555555 grays) are terminal-palette
  # concerns with no luvus theme role.
  home.activation.luvusState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.luvus/themes"
    # rm first: a plain `cp` onto a symlinked path would follow the link
    # into the read-only store and fail (BSD cp has no
    # --remove-destination, so do it portably). The config was a home.file
    # symlink before 2026-08-30 — the rm keeps old generations' symlinks
    # from being followed too.
    $DRY_RUN_CMD rm -f $VERBOSE_ARG "$HOME/.luvus/themes/dracula-custom.toml" "$HOME/.luvus/config.json"
    $DRY_RUN_CMD cp $VERBOSE_ARG "${themeToml}" "$HOME/.luvus/themes/dracula-custom.toml"
    $DRY_RUN_CMD cp $VERBOSE_ARG "${configJson}" "$HOME/.luvus/config.json"
    # cp inherits the store files' 0444; give luvus's atomic-replace
    # normally-permitted files to work with.
    $DRY_RUN_CMD chmod $VERBOSE_ARG 644 "$HOME/.luvus/themes/dracula-custom.toml" "$HOME/.luvus/config.json"
  '';
}
