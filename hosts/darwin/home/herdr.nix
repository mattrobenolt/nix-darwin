_:

{
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [update]
    version_check = false
    manifest_check = false

    [ui]
    agent_panel_sort = "spaces"
    show_agent_labels_on_pane_borders = false

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
  '';
}
