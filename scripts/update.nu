#!/usr/bin/env nu

def main [...groups: string] {
let choices = if ($groups | is-empty) {
  (gum choose --no-limit
    --header "Select inputs to update:"
    $"core    \(nixpkgs · mattware · nix-darwin · home-manager · llm-agents · nixvim · helium\)"
    "ghostty"
    "hyprland  (hyprland + all hypr* followers)"
    "neovim    (neovim-nightly-overlay)"
    "zed       (latest preview release)"
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

if ($choices | any { str starts-with "hyprland" }) {
  print "Updating hyprland..."
  nix flake update hyprland
}

if ($choices | any { str starts-with "neovim" }) {
  print "Updating neovim-nightly-overlay..."
  nix flake update neovim-nightly-overlay
}

if ($choices | any { str starts-with "zed" }) {
  print "Fetching latest Zed preview release..."
  let latest = (
    http get https://api.github.com/repos/zed-industries/zed/releases
    | where prerelease == true
    | first
    | get tag_name
  )
  print $"Updating zed to ($latest)"
  open flake.nix
    | str replace --regex 'zed\.url = "github:zed-industries/zed/[^"]+"' $'zed.url = "github:zed-industries/zed/($latest)"'
    | save -f flake.nix
  nix flake update zed
}

print "Done. Run 'just apply' when ready."
}
