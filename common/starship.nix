_:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$directory$fill$git_branch$git_status$time\n$character";
      add_newline = true;

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "bright-black";
      };

      fill = {
        symbol = " ";
      };

      character = {
        success_symbol = "[\\$](white bold)";
        error_symbol = "[\\$](red bold)";
      };

      directory = {
        style = "cyan";
        truncation_length = 4;
        truncation_symbol = "…/";
        truncate_to_repo = true;
        format = "[ $path]($style)";
        repo_root_style = "cyan bold";
        repo_root_format = "[󰳏 ]($style)[$repo_root]($repo_root_style)[$path]($style)";
      };

      git_branch = {
        symbol = "";
        style = "green";
        format = "[$branch]($style) ";
      };

      git_status = {
        style = "red";
        format = "([$all_status]($style)) ";
        stashed = "";
        untracked = "";
        modified = "*";
      };
    };
  };
}
