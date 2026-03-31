_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "1password-agent" = {
        match = "exec \"test -n '$WAYLAND_DISPLAY'\"";
        identityAgent = "~/.1password/agent.sock";
      };
      "github.com" = {
        user = "git";
      };
    };
  };
}
