# herdr-tab-smart-rename plugin — context-aware names for herdr tabs
# https://github.com/iurysza/herdr-tab-smart-rename
#
# Bun/TypeScript plugin. No compile step — Bun runs TS directly.
# Needs `bun install` for deps at build time, and bun at runtime.
#
# Self-contained: run-bun.sh is rewritten to use nix's bun absolute
# path instead of searching PATH / ~/.bun / homebrew.
{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) bun;

  src = pkgs.fetchFromGitHub {
    owner = "iurysza";
    repo = "herdr-tab-smart-rename";
    rev = "a7bf8e4105732629678fcc2a3203376c07cacc95";
    hash = "sha256-Jzw+uvDm4vBnDsTYGtu+moIh9806rxu8oZGBRWKbIh8=";
  };

  # FOD: bun install with network access. Outputs node_modules as a
  # directory. outputHashMode = "recursive" NAR-hashes the tree, so
  # the hash pins the dep CONTENT — NAR is nix's own canonical
  # serialization, immune to stdenv/tar/gzip rebuilds. The old flat
  # tar+gzip hash instead fingerprinted the platform's stdenv
  # tar/gzip build and re-flipped on every stdenv rebuild with zero
  # dep changes (2026-08-19, 2026-08-31, 2026-09-13). Now only a
  # lockfile change or a bun version that lays out node_modules
  # differently can move this hash.
  bunDeps = pkgs.stdenv.mkDerivation {
    pname = "herdr-tab-smart-rename-bun-deps";
    version = "0.1.1";

    inherit src;

    nativeBuildInputs = [
      bun
      pkgs.cacert
    ];

    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    impureEnvVars = lib.fetchers.proxyImpureEnvVars;

    dontPatchShebangs = true;
    dontStrip = true;

    buildPhase = ''
      export HOME=$(mktemp -d)
      bun install --production --frozen-lockfile
    '';

    installPhase = ''
      mkdir -p $out
      cp -a node_modules $out/
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    # node_modules is pure JS and byte-identical on every platform
    # (verified darwin vs linux 2026-09-01, and across the 2026-09-13
    # stdenv rebuild: two store tarballs, identical trees, different
    # gzip), so one hash covers all systems.
    outputHash = "sha256-ZzRAA4fnpe8vFdzyO/du654eJ6CR5zzJIQCXW9/swSo=";
  };

  herdrTabSmartRename = pkgs.stdenv.mkDerivation {
    pname = "herdr-tab-smart-rename";
    version = "0.1.1";

    inherit src;

    nativeBuildInputs = [ bun ];

    buildPhase = ''
      # Pre-built node_modules from the deps FOD
      cp -a ${bunDeps}/node_modules .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r src node_modules herdr-plugin.toml package.json provider.env.example docs $out/

      # Rewrite run-bun.sh to use nix's bun directly instead of
      # searching PATH, ~/.bun, and homebrew locations.
      cat > $out/src/run-bun.sh << 'EOF'
      #!/bin/sh
      set -eu
      exec "${bun}/bin/bun" "$@"
      EOF
      chmod +x $out/src/run-bun.sh

      runHook postInstall
    '';
  };
in
{
  programs.herdr.plugins."tab-smart-rename" = {
    source = herdrTabSmartRename;
  };
}
