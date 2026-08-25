{ pkgs, inputs, ... }:

{
  # qmd — local hybrid search engine for Markdown (BM25 + vector + reranking)
  # https://github.com/tobi/qmd
  #
  # Take mattware's own evaluated package, NOT the overlay re-evaluated
  # against the host's nixpkgs: CI builds exactly this derivation into
  # mattrobenolt.cachix.org, so cache hits stay reliable regardless of
  # nixpkgs skew between this repo and mattware. (The overlay path meant
  # every nixpkgs bump forced a from-source llama.cpp build — an OOM
  # when the box was 8GB.)
  home.packages = [ inputs.mattware.packages.${pkgs.stdenv.hostPlatform.system}.qmd ];
}
