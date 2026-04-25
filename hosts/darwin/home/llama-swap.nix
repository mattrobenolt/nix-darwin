{ lib, pkgs, ... }:

let
  commonArgs = [
    "llama-server"
    "--host 127.0.0.1"
    "--port \${PORT}"
    "-ngl 99"
    "--flash-attn on"
    "--cache-type-k q8_0"
    "--cache-type-v q8_0"
    "--kv-unified"
    "--jinja"
    "--temp 0.6"
    "--top-p 0.95"
    "--min-p 0.01"
  ];

  localModel =
    repo: file: alias: ctxSize: parallel:
    lib.concatStringsSep " " (
      commonArgs
      ++ [
        "-hf ${repo}"
        "-hff ${file}"
        "--ctx-size ${toString ctxSize}"
        "--parallel ${toString parallel}"
        "--batch-size 2048"
        "--ubatch-size 512"
        ''--alias "${alias}"''
        "--reasoning off"
      ]
    );

  qwen35bBase = [
    "llama-server"
    "-hf unsloth/Qwen3.6-35B-A3B-GGUF"
    "-hff Qwen3.6-35B-A3B-UD-Q6_K_XL.gguf"
    "--host 127.0.0.1"
    "--port \${PORT}"
    "-ngl 99"
    "--ctx-size 262144"
    "--parallel 2"
    "--flash-attn on"
    "--cache-type-k q8_0"
    "--cache-type-v q8_0"
    "--kv-unified"
    "--batch-size 4096"
    "--ubatch-size 1024"
    "--jinja"
    "--temp 0.6"
    "--top-p 0.95"
    "--min-p 0.01"
  ];
  qwen35b = lib.concatStringsSep " " (
    qwen35bBase
    ++ [
      ''--alias "unsloth/Qwen3.6-35B-A3B"''
      "--reasoning on"
    ]
  );
  qwen35bNoReasoning = lib.concatStringsSep " " (
    qwen35bBase
    ++ [
      ''--alias "unsloth/Qwen3.6-35B-A3B-no-reasoning"''
      "--reasoning off"
    ]
  );

  qwen8bBalanced =
    localModel "unsloth/Qwen3-8B-128K-GGUF" "Qwen3-8B-128K-Q5_K_M.gguf" "Qwen/Qwen3-8B-128K" 131072
      1;
  qwen35_9b =
    localModel "unsloth/Qwen3.5-9B-GGUF" "Qwen3.5-9B-Q4_K_M.gguf" "Qwen/Qwen3.5-9B" 262144
      1;
  gemma4_26bA4b =
    localModel "unsloth/gemma-4-26B-A4B-it-GGUF" "gemma-4-26B-A4B-it-UD-Q4_K_M.gguf"
      "google/gemma-4-26B-A4B-it"
      262144
      1;
in
{
  xdg.configFile."llama-swap/config.yaml".source =
    (pkgs.formats.yaml { }).generate "llama-swap-config"
      {
        # First run downloads the model — give it plenty of time.
        healthCheckTimeout = 3600;

        # Show loading progress in chat UIs that support reasoning fields.
        sendLoadingState = true;

        models = {
          "qwen3.6-35b" = {
            cmd = qwen35b;
            ttl = 3600;
          };
          "qwen3.6-35b-no-reasoning" = {
            cmd = qwen35bNoReasoning;
            ttl = 3600;
          };
          "qwen3-8b-balanced" = {
            cmd = qwen8bBalanced;
            ttl = 3600;
          };
          "qwen3.5-9b" = {
            cmd = qwen35_9b;
            ttl = 3600;
          };
          "gemma4-26b-a4b" = {
            cmd = gemma4_26bA4b;
            ttl = 3600;
          };
        };
      };
}
