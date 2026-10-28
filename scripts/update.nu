#!/usr/bin/env nu

def main [...groups: string] {
let choices = if ($groups | is-empty) {
  (gum choose --no-limit
    --header "Select inputs to update:"
    $"core    \(nixpkgs · mattware · nix-darwin · home-manager · llm-agents · nixvim\)"
    "neovim    (neovim-nightly-overlay)"
    "rex     (preview channel)"
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
  nix flake update nixpkgs mattware nix-darwin home-manager llm-agents nixvim z53 porthole usgc-machine-report
}

if ($choices | any { str starts-with "neovim" }) {
  print "Updating neovim-nightly-overlay..."
  nix flake update neovim-nightly-overlay
}

if ($choices | any { str starts-with "rex" }) {
  print "Updating Rex (preview channel)..."
  nix flake update rex
}

print "Done. Run 'just apply' when ready."
}
