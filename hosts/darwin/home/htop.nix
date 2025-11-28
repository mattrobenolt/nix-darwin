_:

{
  programs.htop = {
    enable = true;
    settings = {
      hide_kernel_threads = 1;
      hide_userland_threads = 0;
      show_program_path = 1;
      highlight_deleted_exe = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;
      find_comm_in_cmdline = 1;
      strip_exe_from_cmdline = 1;
      header_margin = 1;
      screen_tabs = 1;
      show_cpu_usage = 1;
      enable_mouse = 1;
      delay = 15;
      header_layout = "two_50_50";
      column_meters_0 = "LeftCPUs2 Memory Swap";
      column_meter_modes_0 = "1 1 1";
      column_meters_1 = "RightCPUs2 Tasks LoadAverage Uptime";
      column_meter_modes_1 = "1 2 2 2";
      tree_view = 1;
      sort_key = 47;
      tree_sort_key = 47;
      sort_direction = -1;
      tree_sort_direction = -1;
    };
  };
}
