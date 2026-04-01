# llmster — headless LM Studio inference server
# Self-contained: options, systemd unit, firewall, packages
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
  lcfg = cfg.llmster;
  llmsterExe =
    if lcfg.package != null
    then "${lcfg.package}/bin/llmster"
    else "${pkgs.llama-cpp}/bin/llama-server";
in
{
  options.modules.features.ai.llmster = {
    enable = lib.mkEnableOption "Enable llmster (LM Studio headless server)";
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Nix package that provides the `llmster` executable.";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address llmster should bind to (keep local for security)";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 1234;
      description = "TCP port for llmster to listen on";
    };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command-line arguments passed to llmster";
    };
  };

  config = lib.mkIf lcfg.enable {
    systemd.services.llmster = {
      description = "LLMStudio llmster (headless LM Studio)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
        ExecStart = lib.concatStringsSep " " (
          [ "${llmsterExe}" "--host" lcfg.host "--port" (toString lcfg.port) ]
          ++ lcfg.extraArgs
        );
        Environment = "CUDA_VISIBLE_DEVICES=0";
        MemoryMax = "80%";
        Nice = -10;
      };
    };

    networking.firewall.allowedTCPPorts = [ lcfg.port ];
  };
}
