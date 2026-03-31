{ pkgs, ... }:

{
  # qmd — local hybrid search engine for Markdown (BM25 + vector + reranking)
  # https://github.com/tobi/qmd
  #
  # Not in nixpkgs (node-llama-cpp native deps resist packaging).
  # Wrapper delegates to bunx which caches the package in ~/.bun/install/cache/.
  home.packages = [
    (pkgs.writeShellScriptBin "qmd" ''
      exec ${pkgs.bun}/bin/bunx @tobilu/qmd@2.0.1 "$@"
    '')
  ];
}
