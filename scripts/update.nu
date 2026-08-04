#!/usr/bin/env nu

def update-herdr [] {
  let latest = (http get https://herdr.dev/latest.json).version

  if not ($latest =~ '^\d+\.\d+\.\d+$') {
    error make { msg: $"Invalid Herdr version from latest.json: ($latest)" }
  }

  let url = $"github:herdrdev/herdr/v($latest)"
  let flake = open --raw flake.nix
  let updated = ($flake | str replace --regex 'github:herdrdev/herdr/v\d+\.\d+\.\d+' $url)

  if $updated != $flake {
    $updated | save --force flake.nix
  } else if not ($flake | str contains $url) {
    error make { msg: "Could not find the pinned Herdr input in flake.nix." }
  }

  nix flake update herdr
}

def main [...groups: string] {
let choices = if ($groups | is-empty) {
  (gum choose --no-limit
    --header "Select inputs to update:"
    $"core    \(nixpkgs · mattware · nix-darwin · home-manager · llm-agents · nixvim · helium\)"
    "ghostty"
    "herdr   (latest stable release)"
    "hyprland  (hyprland + all hypr* followers)"
    "neovim    (neovim-nightly-overlay)"
  ) | lines
} else {
  $groups
}

if ($choices | is-empty) {
  print "Nothing selected."
  exit 0
}

if ($choices | any { str starts-with "core" }) {
  print "Updating core inputs..."
  nix flake update nixpkgs mattware nix-darwin home-manager llm-agents nixvim helium
}

if ($choices | any { str starts-with "ghostty" }) {
  print "Updating ghostty..."
  nix flake update ghostty
}

if ($choices | any { str starts-with "herdr" }) {
  print "Updating Herdr..."
  update-herdr
}

if ($choices | any { str starts-with "hyprland" }) {
  print "Updating hyprland..."
  nix flake update hyprland
}

if ($choices | any { str starts-with "neovim" }) {
  print "Updating neovim-nightly-overlay..."
  nix flake update neovim-nightly-overlay
}

print "Done. Run 'just apply' when ready."
}
