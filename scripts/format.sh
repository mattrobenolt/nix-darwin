#!/usr/bin/env bash
# Format all nix files

set -e

cd "$(dirname "$0")/.."

echo "Formatting nix files..."
treefmt .

echo "✓ Formatting complete"
