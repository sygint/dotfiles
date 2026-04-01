# llmster — LM Studio headless inference daemon
# Self-contained: options, systemd unit, firewall, packages
#
# Uses the standalone llmster package (packages/llmster.nix) which provides
# `lms` CLI and `llmster` daemon via buildFHSEnv wrappers.
#
# Service lifecycle:
#   1. ExecStartPre: `llmster bootstrap` (one-time, idempotent)
#   2. ExecStartPre: `lms daemon up`     (starts background daemon)
#   3. ExecStart:    `lms server start`   (starts HTTP API)
#   4. ExecStop:     `lms daemon down`    (clean shutdown)
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
  lcfg = cfg.llmster;

  # Default to the standalone llmster package if no custom package is provided
  llmsterPkg =
    if lcfg.package != null
    then lcfg.package
    else pkgs.callPackage ../../../../packages/llmster.nix { };

  lmsBin = "${llmsterPkg}/bin/lms";
  llmsterBin = "${llmsterPkg}/bin/llmster";

  # Helper that cd's to /tmp before running lms, avoiding bwrap chdir errors
  # when the calling user's CWD isn't accessible to the service user.
  lmsHelper = pkgs.writeShellScript "lms-helper" ''
    cd /tmp
    exec ${lmsBin} "$@"
  '';

  # Wrapper that delegates to the service user via sudo.
  # Any wheel user can run `lms` commands without knowing the HOME / user details.
  # sudo rule below restricts this to the helper script only.
  lmsWrapper = pkgs.writeShellScriptBin "lms" ''
    exec /run/wrappers/bin/sudo -u ${lcfg.user} -H ${lmsHelper} "$@"
  '';
in
{
  options.modules.features.ai.llmster = {
    enable = lib.mkEnableOption "Enable llmster (LM Studio headless daemon)";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Custom llmster package. Defaults to packages/llmster.nix.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address the LM Studio server should bind to.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 1234;
      description = "TCP port for the LM Studio HTTP API.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "friday";
      description = "System user to run the daemon as.";
    };

    home = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/friday";
      description = "HOME directory for the daemon (stores models, config, state in ~/.lmstudio/).";
    };

    cors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CORS on the HTTP API.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "qwen/qwq-32b" "google/gemma-3-27b" ];
      description = ''
        Model identifiers to download after the daemon starts.
        Uses `lms get <model>` to download if not already present.
        Models are stored in ~/.lmstudio/models/.
      '';
    };

    defaultModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "qwen/qwq-32b";
      description = ''
        Model to auto-load into memory on startup.
        Uses `lms load <model> --yes` after the server starts.
      '';
    };

    gpuOffload = lib.mkOption {
      type = lib.types.str;
      default = "max";
      description = "GPU offloading mode: 'max', 'auto', or a fraction like '0.8'.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional arguments passed to `lms server start`.";
    };
  };

  config = lib.mkIf lcfg.enable {
    # lmsWrapper for interactive use (delegates to service user via sudo);
    # raw llmsterPkg also available for systemd units that run as lcfg.user directly.
    environment.systemPackages = [ lmsWrapper ];

    # Allow wheel users to run lms commands as the service user without a password.
    # Scoped to the helper script path — no wildcard command access.
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${lmsHelper} *";
            options = [ "NOPASSWD" ];
          }
        ];
        runAs = lcfg.user;
      }
    ];

    systemd.services.llmster = {
      description = "LM Studio Headless Daemon (llmster)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = lcfg.user;

        # Bootstrap (idempotent — creates ~/.lmstudio/ structure)
        ExecStartPre = [
          "${llmsterBin} bootstrap"
          "${lmsBin} daemon up"
        ];

        # Start the HTTP API server
        ExecStart = lib.concatStringsSep " " (
          [
            "${lmsBin}"
            "server"
            "start"
            "--port" (toString lcfg.port)
            "--bind" lcfg.host
          ]
          ++ lib.optionals lcfg.cors [ "--cors" ]
          ++ lcfg.extraArgs
        );

        # Clean shutdown
        ExecStop = "${lmsBin} daemon down";

        # Environment
        Environment = [
          "HOME=${lcfg.home}"
          "CUDA_VISIBLE_DEVICES=0"
        ];

        # Resource limits
        MemoryMax = "80%";
        Nice = -10;

        # Allow time for daemon startup
        TimeoutStartSec = 120;
        TimeoutStopSec = 30;
      };
    };

    # Model provisioning service — downloads and optionally loads models
    # Runs after the main llmster service is up
    systemd.services.llmster-models = lib.mkIf (lcfg.models != [ ] || lcfg.defaultModel != null) {
      description = "LM Studio Model Provisioning";
      wantedBy = [ "multi-user.target" ];
      after = [ "llmster.service" ];
      requires = [ "llmster.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = lcfg.user;
        Environment = [
          "HOME=${lcfg.home}"
        ];
        TimeoutStartSec = 3600; # Models can be large — allow 1 hour
      };

      script = ''
        set -euo pipefail

        ${lib.concatMapStringsSep "\n" (model: ''
          echo "Ensuring model: ${model}"
          ${lmsBin} get "${model}" --yes 2>/dev/null || echo "Model ${model} already present or download failed"
        '') lcfg.models}

        ${lib.optionalString (lcfg.defaultModel != null) ''
          echo "Loading default model: ${lcfg.defaultModel}"
          ${lmsBin} load "${lcfg.defaultModel}" --gpu ${lcfg.gpuOffload} --yes || echo "Failed to load ${lcfg.defaultModel}"
        ''}

        echo "Model provisioning complete."
      '';
    };

    # Open the API port (may be overridden by host firewall extraCommands)
    networking.firewall.allowedTCPPorts = [ lcfg.port ];
  };
}
