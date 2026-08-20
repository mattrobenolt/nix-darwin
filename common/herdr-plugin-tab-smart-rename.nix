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
    # node_modules differ per platform (platform-specific native deps),
    # so the tarball hash differs too.
    outputHash =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "sha256-o0LICcwGjk1y6kIlU6C2usCemMYxmA/g1nScJtMYmaU="
      else
        "sha256-f84q24yLwTzQ8+JK8lSqJTTOEerci1WLMv+N67zhqi0=";
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
