# herdr-hunk-diff plugin — review agent-authored changes in hunk
# https://github.com/jhochenbaum/herdr-hunk-diff
#
# TypeScript plugin that needs `npm ci` + `tsc` to build, and ships
# node_modules/ (with the bundled hunkdiff CLI) at runtime.
#
# Self-contained: the nix nodejs absolute path is baked into the
# manifest commands and node_modules/.bin shebangs, so the plugin
# doesn't rely on `node` being on PATH at runtime.
#
# buildNpmPackage's fetchNpmDeps misses `zwitch` (a transitive dep:
# hunkdiff → @pierre/diffs → hast-util-to-html → zwitch) in this
# lockfile v3 tree. Instead, we use a fixed-output derivation (FOD)
# to run `npm ci` with network access — FODs are not sandboxed, so
# npm can reach the registry.
{
  pkgs,
  lib,
  ...
}:
let
  nodejs = pkgs.nodejs_24;

  src = pkgs.fetchFromGitHub {
    owner = "jhochenbaum";
    repo = "herdr-hunk-diff";
    rev = "6810ab31b34ec28eb302603846bc4339e7063655";
    hash = "sha256-P54w2JoIY1OI3Yvhn2g8aAmFeFdxbg49C27lZpU6+pI=";
  };

  # FOD: npm ci with network access. Outputs node_modules as a
  # directory; outputHashMode = "recursive" NAR-hashes the tree, so
  # the hash pins the dep CONTENT. The old flat tar+gzip hash
  # fingerprinted the platform's stdenv tar/gzip build instead and
  # re-flipped on every stdenv rebuild with zero dep changes
  # (2026-08-31, 2026-09-13). NAR is nix's own canonical
  # serialization, so only a lockfile change or an npm version that
  # lays out node_modules differently can move the hash now.
  npmDeps = pkgs.stdenv.mkDerivation {
    pname = "herdr-hunk-diff-npm-deps";
    version = "0.1.0";

    inherit src;

    nativeBuildInputs = [
      nodejs
      pkgs.cacert
    ];

    # The sandbox doesn't have system CA certs, so point npm at nix's.
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    npm_config_cafile = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    impureEnvVars = lib.fetchers.proxyImpureEnvVars;

    # Keep stdenv fixup out of the tree: patchShebangs would rewrite
    # #!/usr/bin/env shebangs to nix store paths and change the hash.
    dontPatchShebangs = true;
    dontStrip = true;

    buildPhase = ''
      export HOME=$(mktemp -d)
      npm ci --ignore-scripts
    '';

    installPhase = ''
      mkdir -p $out
      cp -a node_modules $out/
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    # hunkdiff ships native per-platform binaries (hunkdiff-darwin-arm64
    # vs -linux-arm64/-x64), so node_modules content is genuinely
    # per-system. The entries below are pre-NAR-conversion flat hashes,
    # stale by definition — the first build on each system fails with a
    # mismatch and prints the real NAR got-hash; paste it in.
    outputHash =
      {
        # NAR hash, captured 2026-09-13 post-stdenv-rebuild
        "aarch64-darwin" = "sha256-0Eza8AkXVBrlBoLeOzl5UItsKHG2NkdhC3T70VBkeEw=";
        # NAR hash, captured on launchpad 2026-09-13
        "aarch64-linux" = "sha256-TDAEolPRILrNW9qDV0ls20v4f5O5y6QYPIKlRV4A4IU=";
        # stale flat hash — recapture on next x86_64 nixos build
        "x86_64-linux" = "sha256-f5gTMHyPg9P+laKTfnobL2GywEhyz4onSQ587AErj60=";
      }
      .${pkgs.stdenv.hostPlatform.system}
        or (throw "herdr-hunk-diff: no npmDeps hash for ${pkgs.stdenv.hostPlatform.system}");
  };

  herdrHunkDiff = pkgs.stdenv.mkDerivation {
    pname = "herdr-hunk-diff";
    version = "0.1.0";

    inherit src;

    nativeBuildInputs = [ nodejs ];

    buildPhase = ''
      # Pre-built node_modules from the deps FOD
      cp -a ${npmDeps}/node_modules .

      # Compile TypeScript — invoke tsc directly with nix's node to
      # avoid #!/usr/bin/env shebang issues in the Linux sandbox.
      ${nodejs}/bin/node node_modules/typescript/bin/tsc -p tsconfig.json
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r dist node_modules herdr-plugin.toml package.json skills $out/

      # npm ci --ignore-scripts skips postinstall scripts that set
      # executable permissions on native binaries (e.g. the bundled
      # hunk binary in hunkdiff-<platform>/bin/hunk). Fix them here.
      find $out/node_modules -type f -path '*/bin/hunk' -exec chmod +x {} +

      # Patch shebangs in both node_modules/.bin (symlinks) and the
      # actual script files they point to (e.g. hunkdiff/bin/hunk.cjs
      # has #!/usr/bin/env node → needs nix's node absolute path).
      patchShebangs $out/node_modules/.bin
      patchShebangs $out/node_modules/hunkdiff/bin

      # Rewrite the manifest to use the nix node absolute path instead
      # of bare `node`, so the plugin is self-contained at runtime.
      #
      # Two patterns in the manifest:
      #   1. Direct argv:  command = ["node", "dist/bin/action.js", ...]
      #   2. Shell script: command = ["sh", "-c", "exec node \"...\""]
      substituteInPlace $out/herdr-plugin.toml \
        --replace-fail '"node"' '"${nodejs}/bin/node"' \
        --replace-fail 'exec node ' 'exec ${nodejs}/bin/node '

      runHook postInstall
    '';
  };
in
{
  programs.herdr.plugins."jhochenbaum.hunkdiff" = {
    source = herdrHunkDiff;
  };
}
