{ pkgs, ... }:
{
  home.sessionVariables = {
    HWATCH = "--no-title --color --no-help-banner";
    EZA_COLORS = "uu=36:gu=37:sn=32:sb=32:da=34:ur=34:uw=35:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36:";
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

    shellAliases = {
      ls = "eza --octal-permissions --group";
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
      bindkey "^[[H" beginning-of-line
      bindkey "^[[F" end-of-line
      bindkey "^[[3~" delete-char
      bindkey "^[[2~" overwrite-mode

      geoip() { curl -s http://ip-api.com/json/$1?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query | jq . }
      bq() { jq "$@" | bat -l json }

      ${pkgs.fortune}/bin/fortune | ${pkgs.cowsay}/bin/cowsay -f hellokitty | ${pkgs.lolcat}/bin/lolcat -t
    '';
  };
}
