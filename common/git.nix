_:

{
  programs.git = {
    enable = true;

    settings = {
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
