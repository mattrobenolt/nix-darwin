{ pkgs, ... }:
{
  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTuvuCDtmFBcTEkfOyx1NlUJZPcCJ76cChOt8ACBGKG";
    };

    settings = {
      user = {
        name = "Matt Robenolt";
        email = "m@robenolt.com";
      };

      url."git@github.com:" = {
        insteadOf = "https://github.com";
      };

      http = {
        cookiefile = "~/.gitcookies";
      };

      gpg = {
        format = "ssh";
        ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
      };

      rebase = {
        automerge = true;
        autostash = true;
      };

      merge = {
        conflictstyle = "diff3";
      };

      color = {
        diff = true;
      };

      diff = {
        colorMoved = "default";
      };

      push = {
        default = "current";
      };

      init = {
        defaultBranch = "main";
      };
    };

    ignores = [
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon"

      # Thumbnails
      "._*"

      # Files that might appear on external disk
      ".Spotlight-V100"
      ".Trashes"

      # autoenv
      ".env"
      # Vagrant
      ".vagrant"

      # vim stuff
      "*.un~"
      "Session.vim"
      ".netrwhist"
      "*~"

      ".envrc"
      ".envrc.local"
      ".direnv"
      ".vscode"
      "*.code-workspace"
      "*.kdl"
      "codebook.toml"
      ".zed/"

      ".opencode/"
      ".claude/"

      ".zig-cache/"
      "zig-out/"
    ];
  };
}
