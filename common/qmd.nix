{ inputs, pkgs, ... }:

{
  # qmd — local hybrid search engine for Markdown (BM25 + vector + reranking)
  # https://github.com/tobi/qmd
  #
  # Built from source via qmd's own flake.nix, pinned to a specific commit.
  # Includes the busy_timeout fix for concurrent-access SQLite corruption.
  home.packages = [
    inputs.qmd.packages.${pkgs.system}.default
  ];
}
