{ pkgs, inputs, ... }:

{
  home.sessionVariables = {
    HWATCH = "--no-title --color --no-help-banner";
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

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
      autoload -Uz compinit
      compinit -u
    '';

    initContent = ''
      # Use terminfo for portable key bindings, with hardcoded fallbacks
      # for terminals that don't set terminfo correctly
      typeset -A key
      key[Home]="''${terminfo[khome]}"
      key[End]="''${terminfo[kend]}"
      key[Delete]="''${terminfo[kdch1]}"
      key[Insert]="''${terminfo[kich1]}"

      [[ -n "''${key[Home]}"   ]] && bindkey "''${key[Home]}"   beginning-of-line
      [[ -n "''${key[End]}"    ]] && bindkey "''${key[End]}"    end-of-line
      [[ -n "''${key[Delete]}" ]] && bindkey "''${key[Delete]}" delete-char
      [[ -n "''${key[Insert]}" ]] && bindkey "''${key[Insert]}" overwrite-mode

      # Fallbacks for common terminal escape sequences
      bindkey "^[[H"  beginning-of-line  # xterm
      bindkey "^[OH"  beginning-of-line  # xterm application mode
      bindkey "^[[1~" beginning-of-line  # rxvt/linux console
      bindkey "^[[F"  end-of-line        # xterm
      bindkey "^[OF"  end-of-line        # xterm application mode
      bindkey "^[[4~" end-of-line        # rxvt/linux console
      bindkey "^[[3~" delete-char
      bindkey "^[[2~" overwrite-mode

      geoip() { curl -s http://ip-api.com/json/$1?fields=status,message,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,offset,currency,isp,org,as,asname,reverse,mobile,proxy,hosting,query | jq . }
      bq() { jq "$@" | bat -l json }

      ${pkgs.fortune}/bin/fortune | ${pkgs.cowsay}/bin/cowsay -f hellokitty | ${
        inputs.mattware.packages.${pkgs.stdenv.hostPlatform.system}.prismacat
      }/bin/prismacat --theme "Dracula"
    '';
  };
}
