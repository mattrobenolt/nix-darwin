#!/usr/bin/env bash
# Run all checks: format, lint, and build

set -e

cd "$(dirname "$0")/.."

echo "=== Formatting ==="
./scripts/format.sh

echo ""
echo "=== Linting ==="
./scripts/lint.sh

echo ""
echo "=== Building ==="
darwin-rebuild build --flake .

echo ""
echo "✓ All checks passed! Ready to commit."
