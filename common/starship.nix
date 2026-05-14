{ lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = lib.mkDefault "$hostname$directory$fill$git_branch$git_status$time\n$character";
      add_newline = true;

      hostname = {
        ssh_only = true;
        format = "\\($hostname\\) ";
      };

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
        format = lib.mkDefault "[ $path]($style)";
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

      profiles = {
        claude-code = "$directory $git_branch$git_status$time$fill$claude_model$claude_context";
      };

      claude_model = {
        format = "[$model]($style) ";
        style = "bright-black";
        symbol = "";
      };

      claude_context = {
        format = "[↑$input_tokens ↓$output_tokens]($style) ";
        display = [
          { threshold = 0; style = "bright-black"; }
          { threshold = 80; style = "yellow"; }
          { threshold = 95; style = "red bold"; }
        ];
      };
    };
  };
}
