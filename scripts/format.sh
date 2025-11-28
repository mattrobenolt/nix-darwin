#!/usr/bin/env bash
# Format all nix files using nixfmt-rfc-style

set -e

cd "$(dirname "$0")/.."

echo "Formatting nix files..."
find . -name "*.nix" -type f -exec nixfmt {} \;

echo "✓ Formatting complete"
