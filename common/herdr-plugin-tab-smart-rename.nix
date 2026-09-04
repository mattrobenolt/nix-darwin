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

  # FOD: bun install with network access. Outputs a tarball of
  # node_modules to avoid FOD store-path reference restrictions.
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
      tar --mtime='@0' --sort=name -czf $out node_modules
    '';

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    # One entry per system — not because the deps are platform-specific
    # (they're pure JS; node_modules content is byte-identical across
    # darwin/linux), but because the tarball bytes embed each platform's
    # stdenv tar/gzip build, and those are separate nixpkgs derivations.
    # A nixpkgs bump that rebuilds a platform's stdenv re-flips that
    # platform's hash with zero dep changes (2026-08-31 bump: darwin
    # stdenv rebuilt, o0LI… → X/pOm…; linux untouched, f84q… held). When
    # an entry goes stale, the FOD error prints the actual hash — paste
    # it in.
    outputHash =
      {
        # captured 2026-09-01, post-nixpkgs-bump darwin stdenv rebuild
        "aarch64-darwin" = "sha256-X/pOmMF7K9urNEavZ5glXs8LyN9VRewyZ7qw13O4HBY=";
        # fresh-built on launchpad 2026-09-01 with the current lock
        "aarch64-linux" = "sha256-f84q24yLwTzQ8+JK8lSqJTTOEerci1WLMv+N67zhqi0=";
        # carried over from the old non-darwin branch, never built on
        # x86_64-linux. If the nixos box hits a mismatch, paste the
        # got-hash here.
        "x86_64-linux" = "sha256-f84q24yLwTzQ8+JK8lSqJTTOEerci1WLMv+N67zhqi0=";
      }
      .${pkgs.stdenv.hostPlatform.system}
        or (throw "herdr-tab-smart-rename: no bunDeps hash for ${pkgs.stdenv.hostPlatform.system}");
  };

  herdrTabSmartRename = pkgs.stdenv.mkDerivation {
    pname = "herdr-tab-smart-rename";
    version = "0.1.1";

    inherit src;

    nativeBuildInputs = [ bun ];

    buildPhase = ''
      # Extract pre-built node_modules from the FOD tarball
      tar -xzf ${bunDeps}
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
