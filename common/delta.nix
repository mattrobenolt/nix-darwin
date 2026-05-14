_:

{
  programs.delta = {
    enable = true;
    enableGitIntegration = false;
    options = {
      features = "interactive";
      line-numbers = true;
      syntax-theme = "Dracula";
      diff-highlight = true;
      true-color = "always";
      pager = "less --mouse -RFK";
      hyperlinks = true;
      line-numbers-minus-style = "#FF5555 dim";
      line-numbers-plus-style = "#50FA7B dim";
    };
  };
}
