_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "Match exec \"test -n \\\"$WAYLAND_DISPLAY\\\"\"" = {
        IdentityAgent = "~/.1password/agent.sock";
      };
      "github.com" = {
        User = "git";
      };
    };
  };
}
