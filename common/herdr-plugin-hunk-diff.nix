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
# npm can reach the registry. The output is a tarball (not a
# directory) to avoid FOD store-path reference restrictions.
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

  # FOD: npm ci with network access. Outputs a tarball of node_modules
  # (not a directory) to avoid FOD store-path reference restrictions.
  # The output hash pins the entire dep closure.
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

    # Pack as tarball so the FOD output can't reference store paths.
    dontPatchShebangs = true;
    dontStrip = true;

    buildPhase = ''
      export HOME=$(mktemp -d)
      npm ci --ignore-scripts
    '';

    installPhase = ''
      tar --mtime='@0' --sort=name -czf $out node_modules
    '';

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    # node_modules differ per platform (hunkdiff-darwin-arm64 vs
    # hunkdiff-linux-arm64, etc.), so the tarball hash differs too.
    outputHash =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "sha256-+SNmcslCanC9zjLA25dlhNx41h0JULdM0V4fAv6+NRg="
      else
        "sha256-f5gTMHyPg9P+laKTfnobL2GywEhyz4onSQ587AErj60=";
  };

  herdrHunkDiff = pkgs.stdenv.mkDerivation {
    pname = "herdr-hunk-diff";
    version = "0.1.0";

    inherit src;

    nativeBuildInputs = [ nodejs ];

    buildPhase = ''
      # Extract pre-built node_modules from the FOD tarball
      tar -xzf ${npmDeps}

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
