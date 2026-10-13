# herdr-tab-smart-rename plugin — context-aware names for herdr tabs
# https://github.com/iurysza/herdr-tab-smart-rename
#
# Bun/TypeScript plugin. No compile step — Bun runs TS directly.
# Needs `bun install` for deps at build time, and bun at runtime.
#
# Self-contained: 0.6.x manifests invoke bare `bun` (upstream dropped
# the run-bun.sh PATH shim), so herdr-plugin.toml is rewritten at
# build time to use nix's bun absolute path.
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
    # v0.6.1
    rev = "f66cd1050e6feebfe55f81a2a3962f63b628ba95";
    hash = "sha256-aYxJLFBL7nPEbN2S/wgdEJYEso9B48uWFLeKk55lk4E=";
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
    version = "0.6.1";

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
    # 0.6.1's dep tree pulls platform-conditional binaries (esbuild
    # darwin-arm64 vs linux-arm64), so node_modules content is per
    # system. One NAR hash per platform, like herdr-hunk-diff.
    outputHash =
      {
        # NAR hash, captured 2026-10-08
        "aarch64-darwin" = "sha256-E/WDN06j9vrFMxWu6fhWzsSU8yvkV+EzVmjG7obdHqQ=";
        # NAR hash, captured on launchpad 2026-10-08
        "aarch64-linux" = "sha256-KwMD6bk2VA5F8b/yt+Dz7iecqZxpV/EvU6FV65OzBaY=";
      }
      .${pkgs.stdenv.hostPlatform.system}
        or (throw "herdr-tab-smart-rename: no bunDeps hash for ${pkgs.stdenv.hostPlatform.system}");
  };

  herdrTabSmartRename = pkgs.stdenv.mkDerivation {
    pname = "herdr-tab-smart-rename";
    version = "0.6.1";

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

      # Rewrite the manifest to use nix's bun absolute path instead of
      # bare `bun`, so the plugin is self-contained at runtime.
      substituteInPlace $out/herdr-plugin.toml \
        --replace-fail '"bun"' '"${bun}/bin/bun"'

      runHook postInstall
    '';
  };
in
{
  programs.herdr.plugins."tab-smart-rename" = {
    source = herdrTabSmartRename;
  };
}
