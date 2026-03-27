_:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "interactive";
      line-numbers = true;
      syntax-theme = "Dracula";
      diff-highlight = true;
      true-color = "always";
      pager = "less --RAW-CONTROL-CHARS --mouse --quit-if-one-screen";
      hyperlinks = true;
      line-numbers-minus-style = "#FF5555 dim";
      line-numbers-plus-style = "#50FA7B dim";
    };
  };
}
