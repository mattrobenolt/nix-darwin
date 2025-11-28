#!/usr/bin/env bash
# Lint nix files using statix and deadnix

set -e

cd "$(dirname "$0")/.."

echo "Running statix (linter)..."
statix check .

echo ""
echo "Running deadnix (find dead code)..."
deadnix --fail .

echo ""
echo "✓ All checks passed"
