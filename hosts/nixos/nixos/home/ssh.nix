_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "1password-agent" = {
        match = "exec \"test -S ~/.1password/agent.sock\"";
        identityAgent = "~/.1password/agent.sock";
      };
      "github.com" = {
        user = "git";
      };
    };
  };
}
