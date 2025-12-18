_:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include OrbStack SSH config
    includes = [ "~/.orbstack/ssh/config" ];

    matchBlocks = {
      # Global settings for all hosts
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          UseKeychain = "yes";
          IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
        };
      };

      # Diskstation - password auth only
      "diskstation.local" = {
        extraOptions = {
          PubkeyAuthentication = "no";
          PreferredAuthentications = "password";
        };
      };

      # GitHub
      "github.com" = {
        user = "git";
      };

      # Personal server
      "robenolt.com" = {
        user = "m";
      };
    };
  };
}
