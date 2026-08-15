{ lib, ... }:

let
  sshKeys = import ./ssh-keys.nix { inherit lib; };
in

{
  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      format = "ssh";
      # Same key as the SSH identity; canonical source: common/ssh-keys.nix.
      key = sshKeys.mattMain;
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
      };

      rebase = {
        automerge = true;
        autostash = true;
      };

      merge = {
        conflictstyle = "zdiff3";
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
      ".pi-subagents/"
    ];
  };
}
