_:

{
  programs.zellij = {
    enable = true;
    settings = {
      theme = "dracula";
      default_mode = "normal";
      pane_frames = true;
      scroll_buffer_size = 100000;
      show_startup_tips = false;
    };
  };
}
