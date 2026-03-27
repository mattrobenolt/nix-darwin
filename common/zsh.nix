_:

{
  programs.zsh.initContent = ''
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
  '';
}
