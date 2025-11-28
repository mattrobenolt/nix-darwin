{ ... }:

{
  imports = [
    ./home/atuin.nix
    ./home/bat.nix
    ./home/btop.nix
    ./home/direnv.nix
    ./home/ghostty.nix
    ./home/htop.nix
    ./home/neovim.nix
    ./home/yazi.nix
    ./home/zellij.nix
    ./home/zsh.nix
  ];

  programs.git = {
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTuvuCDtmFBcTEkfOyx1NlUJZPcCJ76cChOt8ACBGKG";
    };

    settings = {
      user = {
        name = "Matt Robenolt";
        email = "matt@ydekproductions.com";
      };

      url."git@github.com:" = {
        insteadOf = "https://github.com";
      };

      http = {
        cookiefile = "~/.gitcookies";
      };

      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "interactive";
      line-numbers = true;
      syntax-theme = "Dracula";
      diff-highlight = true;
      true-color = "always";
      pager = "less --RAW-CONTROL-CHARS --mouse --quit-if-one-screen";
      hyperlinks = true;
      line-numbers-minus-style = "#FF5555 dim";
      line-numbers-plus-style = "#50FA7B dim";
    };
  };
}
