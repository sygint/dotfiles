{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
in
{
  config = lib.mkIf (cfg.llmster.enable) {
    systemd.services.llmster = {
      description = "LLMStudio llmster (headless LM Studio)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = let
        llmsterExe = if cfg.llmster.package != null then "${cfg.llmster.package}/bin/llmster" else "${pkgs.llama-cpp}/bin/llama-server";
        extra = lib.concatStringsSep " " cfg.llmster.extraArgs;
      in {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
        ExecStart = ''${llmsterExe} --host ${cfg.llmster.host} --port ${toString cfg.llmster.port} ${extra}'';
        Environment = "CUDA_VISIBLE_DEVICES=0";
        MemoryMax = "80%";
        Nice = -10;
      };
    };
  };
}
