{ pkgs, ... }:

{
  # qmd — local hybrid search engine for Markdown (BM25 + vector + reranking)
  # https://github.com/tobi/qmd
  home.packages = [ pkgs.qmd ];
}
