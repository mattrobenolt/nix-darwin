{ pkgs, lib, ... }:

let
  # rtk reads config.toml from the platform config dir (dirs::config_dir), which
  # is ~/Library/Application Support on darwin and ~/.config on Linux. The file
  # is written with std::fs::write, so a store symlink makes rtk's own writers
  # (`rtk config --create`, `rtk config recall`, the telemetry consent prompt)
  # fail with EROFS. consent_given = false short-circuits the prompt, so
  # `rtk init` leaves the file alone.
  #
  # [tee] is the legacy section; rtk migrates it to [retriever] at load. Write
  # the current schema so nothing migrates in memory.
  config = ''
    [tracking]
    enabled = true
    history_days = 90

    [display]
    colors = true
    emoji = true
    max_width = 120

    [filters]
    ignore_dirs = [
      ".git",
      "node_modules",
      "target",
      "__pycache__",
      ".venv",
      "vendor",
      ".zig-cache",
    ]
    ignore_files = [
      "*.lock",
      "*.min.js",
      "*.min.css",
    ]

    [retriever]
    mode = "tee"
    max_entry_bytes = 10485760
    max_entries = 200
    retention_days = 30
    compression = true
    tee_max_files = 20
    tee_max_file_size = 1048576
    tee_on_success = false

    [telemetry]
    enabled = false
    consent_given = false

    # `npm run lint` must not become `rtk lint` — that assumes ESLint.
    [hooks]
    exclude_commands = [
      '^pnpm\s+lint(\s|$)',
      '^npm\s+((run|run-script|rum|urn|x)\s+)?lint(\s|$)',
    ]

    [limits]
    grep_max_results = 200
    grep_max_per_file = 25
    status_max_files = 15
    status_max_untracked = 10
    passthrough_max_chars = 2000

    [awareness]
    level = "default"
  '';
in
{
  # No programs.rtk in home-manager; the package comes from the
  # llmAgentsRtkOverlay in flake.nix.
  home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Application Support/rtk/config.toml".text = config;
  };

  xdg.configFile = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
    "rtk/config.toml".text = config;
  };
}
