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
        # Verification half of ssh signing: which keys may sign as which
        # committer email. git matches the principal against the committer
        # email of the object being verified, and every host signs as
        # m@robenolt.com, so the file lists both keys under that one
        # principal (matt's Mac key + the launchpad's own key).
        ssh.allowedSignersFile = "~/.ssh/allowed_signers";
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

  # The allowed_signers trust list for the setting above. namespaces="git"
  # scopes trust to git signatures (commits and tags both use the "git"
  # sshsig namespace). Verification is plain ssh-keygen -Y verify, so it
  # works headless everywhere — no agent, no 1Password.
  home.file.".ssh/allowed_signers".text = ''
    m@robenolt.com namespaces="git" ${sshKeys.mattMain}
    m@robenolt.com namespaces="git" ${sshKeys.launchpadMain}
  '';
}
