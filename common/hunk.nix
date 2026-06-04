_:

{
  programs.hunk = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      theme = "custom";
      line_numbers = true;
      mode = "auto";

      custom_theme = {
        base = "midnight";
        label = "Dracula";
        background = "#191a24";
        panel = "#191a24";
        panelAlt = "#343746";
        border = "#44475a";
        accent = "#bd93f9";
        accentMuted = "#6272a4";
        text = "#f8f8f2";
        muted = "#6272a4";
        addedBg = "#203a2f";
        removedBg = "#4a2530";
        contextBg = "#191a24";
        addedContentBg = "#263f34";
        removedContentBg = "#512b36";
        contextContentBg = "#191a24";
        addedSignColor = "#50fa7b";
        removedSignColor = "#ff5555";
        lineNumberBg = "#21222c";
        lineNumberFg = "#6272a4";
        selectedHunk = "#44475a";
        badgeAdded = "#50fa7b";
        badgeRemoved = "#ff5555";
        badgeNeutral = "#8be9fd";
        fileNew = "#50fa7b";
        fileDeleted = "#ff5555";
        fileRenamed = "#ffb86c";
        fileModified = "#f1fa8c";
        fileUntracked = "#8be9fd";
        noteBorder = "#bd93f9";
        noteBackground = "#21222c";
        noteTitleBackground = "#44475a";
        noteTitleText = "#f8f8f2";

        syntax = {
          default = "#f8f8f2";
          keyword = "#ff79c6";
          string = "#f1fa8c";
          comment = "#6272a4";
          number = "#bd93f9";
          function = "#50fa7b";
          property = "#8be9fd";
          type = "#8be9fd";
          punctuation = "#f8f8f2";
        };
      };
    };
  };
}
