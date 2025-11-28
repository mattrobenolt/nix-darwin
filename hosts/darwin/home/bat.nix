_:

{
  programs.bat = {
    enable = true;
    config = {
      theme = "Dracula";
      style = "numbers";
      paging = "always";
      pager = "less -RF";
    };
  };
}
