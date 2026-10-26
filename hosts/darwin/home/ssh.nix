_:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Rex owns ~/.config/rex/ssh_config (written by `rex terminfo setup`,
    # rewritten by Rex, so it stays out of this file). The Include must stay
    # above any SetEnv: ssh keeps the first one it sees. The guard downgrades
    # TERM=xterm-rex to xterm-256color for hosts without the terminfo entry.
    # Remove with `rex terminfo remove`.
    includes = [
      "~/.config/rex/ssh_config"
      # Include OrbStack SSH config
      "~/.orbstack/ssh/config"
    ];

    settings = {
      # Global settings for all hosts
      "*" = {
        AddKeysToAgent = "yes";
        # UseKeychain is Apple-specific (not in vanilla OpenSSH). IgnoreUnknown
        # makes nixpkgs' ssh silently skip it instead of erroring out, while
        # Apple's /usr/bin/ssh still honors it. Nix sorts attrset keys
        # alphabetically, so IgnoreUnknown precedes UseKeychain in the output.
        IgnoreUnknown = "UseKeychain";
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

      "launchpad" = {
        # MagicDNS over the tailnet; the security group no longer opens 22/tcp.
        HostName = "launchpad.tail45c3.ts.net";
        User = "matt";
      };

      # Break-glass: public IP still assigned (EIP), but 22/tcp is closed at the
      # SG. Needs an SG change or SSM before it connects.
      "launchpad-eip" = {
        HostName = "52.25.100.5";
        User = "matt";
      };
    };
  };
}
