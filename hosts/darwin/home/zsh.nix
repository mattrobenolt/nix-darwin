{ osConfig, ... }:

{
  home.sessionVariables = {
    PYTHONDONTWRITEBYTECODE = "1";
    KUBECTL_EXTERNAL_DIFF = "delta";
    HOMEBREW_PREFIX = "/opt/homebrew";
    HOMEBREW_CELLAR = "/opt/homebrew/Cellar";
    HOMEBREW_REPOSITORY = "/opt/homebrew";
    UV_PYTHON_REFERENCE = "only-managed";
    PSKUBE_NO_COLOR = "1";
  };

  home.sessionPath = [
    "/run/current-system/sw/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.bun/bin"
    "$HOME/.orbstack/bin"
    "/opt/homebrew/opt/ruby@3/bin"
    "/opt/homebrew/lib/ruby/gems/3.2.0/bin"
    "$HOME/.rbenv/shims"
  ];

  programs.zsh = {
    shellAliases = {
      ".." = "cd ../";
      "..." = "cd ../../";
      nproc = "sysctl -n hw.perflevel0.logicalcpu";
      pssh = "ps-turtle ssh";
      jq = "jaq";
      lg = "lazygit";
      darwin-update = "sudo darwin-rebuild switch --flake ~/.config/nix-darwin#${osConfig.networking.hostName}";
    };

    initContent = ''
      export MANPATH="/opt/homebrew/share/man''${MANPATH+:$MANPATH}:"
      export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
    '';
  };
}
