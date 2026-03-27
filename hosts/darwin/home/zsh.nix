{ pkgs, osConfig, ... }:

{
  home.sessionVariables = {
    PYTHONDONTWRITEBYTECODE = "1";
    KUBECTL_EXTERNAL_DIFF = "delta";
    HWATCH = "--no-title --color --no-help-banner";
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
    enable = true;
    defaultKeymap = "emacs";

    shellAliases = {
      ".." = "cd ../";
      "..." = "cd ../../";
      nproc = "sysctl -n hw.perflevel0.logicalcpu";
      pssh = "ps-turtle ssh";
      jq = "jaq";
      lg = "lazygit";
      darwin-update = "sudo darwin-rebuild switch --flake ~/.config/nix-darwin#${osConfig.networking.hostName}";
    };

    history = {
      path = "$HOME/.zsh_history";
      size = 50000;
      save = 10000;
      expireDuplicatesFirst = true;
      extended = true;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    setOptions = [
      "auto_pushd"
      "hist_find_no_dups"
      "hist_save_no_dups"
      "hist_verify"
      "nonomatch"
      "pushd_ignore_dups"
      "pushdminus"
    ];

    localVariables = {
      TIMEFMT = "%U user / %S system / %P cpu %*E total / %Mk maxmem";
    };

    completionInit = ''
      zstyle :compinstall filename '/Users/matt/.zshrc'
      autoload -Uz compinit
      compinit -u
    '';

    initContent = ''
      export MANPATH="/opt/homebrew/share/man''${MANPATH+:$MANPATH}:"
      export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"

      geoip() { curl -s http://ip-api.com/json/$1?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query | jq . }
      bq() { jq "$@" | bat -l json }

      ${pkgs.fortune}/bin/fortune | ${pkgs.cowsay}/bin/cowsay -f hellokitty
    '';
  };
}
