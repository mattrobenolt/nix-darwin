_:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];

    settings = {
      search_mode = "fulltext";
      filter_mode = "global";
      workspaces = false;
      filter_mode_shell_up_key_binding = "session";
      style = "compact";
      inline_height = 20;
      invert = true;
      show_help = false;
      show_tabs = false;
      enter_accept = true;

      stats = {
        common_subcommands = [
          "apt"
          "cargo"
          "composer"
          "dnf"
          "docker"
          "git"
          "go"
          "ip"
          "kubectl"
          "nix"
          "nmcli"
          "npm"
          "pecl"
          "pnpm"
          "podman"
          "port"
          "systemctl"
          "tmux"
          "yarn"
          "nomad"
          "vault"
          "packer"
        ];
      };

      sync = {
        records = true;
      };
    };
  };
}
