# Declarative herdr plugin management via home-manager.
#
# Plugins are pinned by providing a nix store path (typically from
# pkgs.fetchFromGitHub) that contains a herdr-plugin.toml manifest.
# The module links/unlinks plugins through herdr's CLI at activation
# time, keeping plugins.json in sync with your nix config.
#
# Herdr re-reads each manifest from its original (store) path on
# startup, and `herdr plugin link` is idempotent, so store-path churn
# across rebuilds is handled automatically: the activation script
# re-links every enabled plugin each switch, updating the registered
# path.
#
# A tracking file (~/.config/herdr/nix-managed-plugins) records which
# plugin IDs this module owns, so removed plugins are cleanly unlinked
# without touching manually-installed ones.
#
# Usage:
#
#   programs.herdr.plugins."example.my-plugin".source =
#     pkgs.fetchFromGitHub {
#       owner = "owner"; repo = "repo";
#       rev = "abc123"; hash = "sha256-...";
#     };
#
# For a plugin in a subdirectory:
#
#   programs.herdr.plugins."example.sub".source =
#     "${pkgs.fetchFromGitHub { ... }}/subdir";
#
# For a plugin that needs a build step (npm ci, cargo build, etc.),
# compose the build yourself and point source at the result:
#
#   programs.herdr.plugins."example.built".source =
#     let raw = pkgs.fetchFromGitHub { ... };
#     in pkgs.runCommand "herdr-plugin-built" {
#       nativeBuildInputs = [ pkgs.nodejs ];
#     } ''
#       cp -r ${raw}/* .
#       chmod -R u+w .
#       npm ci && npm run build
#       cp -r . $out
#     '';
#
# Set `enable = false` to temporarily disable a plugin without removing
# it from your config:
#
#   programs.herdr.plugins."example.my-plugin" = {
#     source = pkgs.fetchFromGitHub { ... };
#     enable = false;
#   };
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.programs.herdr;

  herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  herdrBin = "${herdrPkg}/bin/herdr";

  trackingFile = "${config.xdg.configHome}/herdr/nix-managed-plugins";

  declaredIds = builtins.attrNames cfg.plugins;
  declaredIdsStr = lib.concatStringsSep " " declaredIds;

  enabledPlugins = lib.filterAttrs (_: p: p.enable) cfg.plugins;
  disabledIds = lib.mapAttrsToList (id: _p: id) (lib.filterAttrs (_: p: !p.enable) cfg.plugins);

  # Link each enabled plugin — idempotent, updates the store path if
  # the derivation hash changed across rebuilds. Failures (e.g. protocol
  # mismatch after a herdr upgrade with a stale server) are warned but
  # non-fatal so activation doesn't block; re-run `just apply` after
  # restarting the herdr server.
  linkLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (_id: p: ''
      echo "  herdr-plugins: link ${p.source}"
      if ! $DRY_RUN_CMD ${herdrBin} plugin link ${p.source} >/dev/null 2>&1; then
        echo "  herdr-plugins: WARNING: link failed — herdr server may need restart"
        echo "  herdr-plugins:   run: herdr server stop && herdr, then just apply"
      fi
    '') enabledPlugins
  );

  # Unlink disabled plugins (harmless if not currently linked).
  unlinkDisabledLines = lib.concatStringsSep "\n" (
    map (id: ''
      echo "  herdr-plugins: unlink disabled ${id}"
      $DRY_RUN_CMD ${herdrBin} plugin unlink ${id} >/dev/null 2>&1 || true
    '') disabledIds
  );

  # Shell-quoted ID list for the tracking-file write.
  quotedIds = lib.concatMapStringsSep " " (id: "'${id}'") declaredIds;
in
{
  options.programs.herdr = {
    plugins = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.path;
              description = ''
                Path to the plugin directory containing herdr-plugin.toml.
                Pin via pkgs.fetchFromGitHub or any derivation that produces
                a directory with the manifest. For subdirectories, use
                string interpolation: `"''${pkgs.fetchFromGitHub { ... }}/subdir"`.
              '';
            };

            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether to link this plugin into herdr. Set to false to
                temporarily disable a plugin without removing it from
                your config.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Herdr plugins to declaratively manage via nix. Each attribute key
        should match the plugin's manifest id (the `id` field in
        herdr-plugin.toml) so that unlink works correctly.
      '';
    };
  };

  # Always run the activation script — even when plugins is empty, we
  # need it to unlink plugins that were removed from the config. The
  # script is a no-op when there are no declared plugins and no tracking
  # file. (Gating on cfg.plugins != {} would skip cleanup on the switch
  # that removes the last plugin.)
  config = {
    home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "herdr-plugins: syncing ${toString (builtins.length declaredIds)} plugin(s)"

      # Unlink plugins that were previously managed but are no longer
      # declared (removed from config). The tracking file records which
      # IDs this module owns — manually-installed plugins are never touched.
      if [ -f "${trackingFile}" ]; then
        while IFS= read -r prev_id; do
          [ -n "$prev_id" ] || continue
          case " ${declaredIdsStr} " in
            *" $prev_id "*) ;; # still declared — skip
            *)
              echo "  herdr-plugins: unlink removed $prev_id"
              if ! $DRY_RUN_CMD ${herdrBin} plugin unlink "$prev_id" >/dev/null 2>&1; then
                echo "  herdr-plugins: WARNING: unlink failed — herdr server may need restart"
              fi
              ;;
          esac
        done < "${trackingFile}"
      fi

      ${unlinkDisabledLines}

      ${linkLines}

      # Write tracking file with all declared IDs (enabled + disabled)
      # so that future removals can be detected and unlinked. When no
      # plugins are declared, write an empty file (or remove it).
      $DRY_RUN_CMD mkdir -p "$(dirname "${trackingFile}")"
      printf '%s\n' ${quotedIds} > "${trackingFile}"
    '';
  };
}
