{ config, lib, pkgs, ... }:

let
  old = config.modules.features."ai-services";
in
{
  # If legacy ai-services settings exist, map them into the new modules.features.ai namespace
  config = lib.mkIf (old != null) {
    modules.features.ai = {
      enable = lib.mkIf (old.enable == true) true false;
      openWebui = {
        enable = lib.mkIf (old.enableOpenWebui == true) true false;
        port = if old.openWebui != null && old.openWebui.port != null then old.openWebui.port else 8888;
      };
      llmster = {
        enable = lib.mkIf (old.enableLlamaServer == true) true false;
        port = 1234;
      };
      ollama = {
        enable = lib.mkIf (old.enableOllmcp == true) true false;
        port = if old.ollama != null && old.ollama.port != null then old.ollama.port else 11434;
      };
      # Preserve some commonly used flags
      enableOllmcp = old.enableOllmcp;
      enableGpuFanControl = old.enableGpuFanControl;
      gpuFanSpeed = old.gpuFanSpeed;
    };
  };
}
