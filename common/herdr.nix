_:

{
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [update]
    version_check = false
    manifest_check = false

    [ui]
    agent_panel_sort = "priority"
    show_agent_labels_on_pane_borders = false
    status_indicators = "symbols"

    # Sidebar row layouts — tuned for running many pi agents at once.
    # Drop the redundant `agent` token (always pi) in favor of state_text
    # for triage and terminal_title_stripped so each row shows what the
    # agent is actually doing. Pi emits a title like
    #   "π · nix-darwin · accounts/fireworks/models/glm-5p2"
    # so line 2 is the live activity. status_indicators = "symbols" above
    # makes the state_icon a distinct shape, not just a color.
    [ui.sidebar.agents]
    row_gap = 0
    rows = [
      ["state_icon", "workspace", "pane"],
      ["terminal_title_stripped"],
    ]

    [ui.sidebar.spaces]
    row_gap = 0
    rows = [
      ["state_icon", "workspace"],
      ["branch", "git_status"],
    ]

    [ui.toast]
    delivery = "herdr"

    [theme]
    name = "dracula"
    auto_switch = false

    [session]
    resume_agents_on_restore = true

    [experimental]
    allow_nested = true
    kitty_graphics = true

    # jhochenbaum.hunkdiff — review agent-authored changes in hunk.
    # These are the same bindings `setup-keys` would install; managed
    # declaratively here because config.toml is a read-only nix symlink.
    [[keys.command]]
    key = "prefix+shift+h"
    type = "plugin_action"
    command = "jhochenbaum.hunkdiff.review"
    description = "hunk: review changes"

    [[keys.command]]
    key = "prefix+shift+s"
    type = "plugin_action"
    command = "jhochenbaum.hunkdiff.send-review"
    description = "hunk: send review to agent"

    [[keys.command]]
    key = "prefix+shift+c"
    type = "plugin_action"
    command = "jhochenbaum.hunkdiff.review:commit"
    description = "hunk: review the last commit"

    [[keys.command]]
    key = "prefix+shift+a"
    type = "plugin_action"
    command = "jhochenbaum.hunkdiff.review:staged"
    description = "hunk: review staged changes"

    # tab-smart-rename — context-aware tab names.
    [[keys.command]]
    key = "prefix+t"
    type = "plugin_action"
    command = "tab-smart-rename.rename-now"
    description = "smart rename current tab"

    [[keys.command]]
    key = "prefix+alt+t"
    type = "plugin_action"
    command = "tab-smart-rename.rename-all"
    description = "force smart rename all tabs"
  '';
}
