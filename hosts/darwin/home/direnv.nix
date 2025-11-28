_:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    stdlib = ''
      layout_uv() {
        export UV_PYTHON="$1"
        local python_version
        read -r python_version <<<$(uv run - <<'EOF'
      import platform
      print('.'.join(platform.python_version_tuple()))
      EOF
      )
        if [[ -z $python_version ]]; then
          log_error "Could not find python's version"
          return 1
        fi
        log_status "Using python $python_version"
        VIRTUAL_ENV=$(direnv_layout_dir)/python-$python_version

        if [[ ! -d $VIRTUAL_ENV ]]; then
          log_status "No virtualenv exists, creating one."
          uv venv --quiet "$VIRTUAL_ENV"
          local pip="$VIRTUAL_ENV/bin/pip"
          cat >> "$pip" <<'EOF'
      #!/usr/bin/env bash
      exec uv pip "$@"
      EOF
          chmod +x "$pip"

          local version=$python_version
          version=''${version%.*}
          ln -s pip "$pip$version"
          version=''${version%.*}
          ln -s pip "$pip$version"
        fi

        export VIRTUAL_ENV
        export UV_ACTIVE=1
        PATH_add "$VIRTUAL_ENV/bin"
      }
    '';
  };
}
