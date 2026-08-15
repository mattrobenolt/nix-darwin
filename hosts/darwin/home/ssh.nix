_:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include OrbStack SSH config
    includes = [ "~/.orbstack/ssh/config" ];

    settings = {
      # Global settings for all hosts
      "*" = {
        AddKeysToAgent = "yes";
        UseKeychain = "yes";
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };

      # Diskstation - password auth only
      "diskstation.local" = {
        PubkeyAuthentication = "no";
        PreferredAuthentications = "password";
      };

      # GitHub
      "github.com" = {
        User = "git";
      };

      # Personal server
      "robenolt.com" = {
        User = "m";
      };

      # Desktop PC
      "nixos.local" = {
        User = "matt";
        ForwardAgent = true;
      };

      # EC2 agent box. EIP is stable across stop/retype resizes;
      # the tailscale hostname replaces this once the box joins the tailnet.
      "launchpad" = {
        HostName = "52.25.100.5";
        User = "matt";
      };
    };
  };
}
