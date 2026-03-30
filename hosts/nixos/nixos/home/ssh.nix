_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      Match exec "test -S ~/.1password/agent.sock"
        IdentityAgent ~/.1password/agent.sock
    '';

    matchBlocks = {
      "github.com" = {
        user = "git";
      };
    };
  };
}
