{ pkgs, ... }:

{
  # qmd — local hybrid search engine for Markdown (BM25 + vector + reranking)
  # https://github.com/tobi/qmd
  #
  # Not in nixpkgs (node-llama-cpp native deps resist packaging).
  # Installed once into ~/.local/share/qmd, then exec'd directly.
  home.packages = let qmdVersion = "2.0.1"; in [
    (pkgs.writeShellScriptBin "qmd" ''
      QMD_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/qmd/${qmdVersion}"
      if [ ! -d "$QMD_DIR/node_modules" ]; then
        mkdir -p "$QMD_DIR"
        (cd "$QMD_DIR" && ${pkgs.bun}/bin/bun add --trust @tobilu/qmd@${qmdVersion})
      fi
      exec "$QMD_DIR/node_modules/.bin/qmd" "$@"
    '')
  ];
}
