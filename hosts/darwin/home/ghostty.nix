_:

{
  xdg.configFile."ghostty/Dracula".text = ''
    palette = 0=#000000
    palette = 1=#ff5555
    palette = 2=#50fa7b
    palette = 3=#f1fa8c
    palette = 4=#bd93f9
    palette = 5=#ff79c6
    palette = 6=#8be9fd
    palette = 7=#bbbbbb
    palette = 8=#555555
    palette = 9=#ff5555
    palette = 10=#50fa7b
    palette = 11=#f1fa8c
    palette = 12=#bd93f9
    palette = 13=#ff79c6
    palette = 14=#8be9fd
    palette = 15=#ffffff
    background = 191a24
    foreground = f8f8f2
    cursor-color = bbbbbb
    selection-background = 44475a
    selection-foreground = ffffff
  '';

  xdg.configFile."ghostty/config".text = ''
    config-file = ./Dracula
    font-family = "Hack Nerd Font Mono"
    font-size = 13
    adjust-cell-height = 10%

    cursor-style = bar
    cursor-style-blink = true
    shell-integration-features = true

    window-padding-x = 8
    window-padding-y = 8

    command = /run/current-system/sw/bin/zsh

    confirm-close-surface = true

    window-save-state = always
    cursor-click-to-move = true

    window-vsync = true

    minimum-contrast = 1

    unfocused-split-opacity = 0.8

    macos-secure-input-indication = false
    macos-titlebar-style = tabs
    macos-option-as-alt = left

    macos-icon = custom-style
    macos-icon-frame = aluminum
    macos-icon-ghost-color = #000000
    macos-icon-screen-color = #000000,#000000

    quick-terminal-autohide = false
    quick-terminal-position = center
    keybind = shift+enter=text:\n

    auto-update = off
    auto-update-channel = tip
  '';
}
