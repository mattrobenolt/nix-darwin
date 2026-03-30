{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    config = {
      global = {
        bash_path = "${pkgs.bash}/bin/bash";
        hide_env_diff = true;
        warn_timeout = "1m";
        strict_env = true;
      };
    };
  };
}
