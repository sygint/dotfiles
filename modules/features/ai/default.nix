# AI services — inference workload tuning + service imports
# GPU/NVIDIA infrastructure lives in modules/hardware/nvidia.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
in
{
  options.modules.features.ai = {
    enable = lib.mkEnableOption "AI services namespace (openwebui, ollama, llmster)";
  };

  # Import per-service submodules (each declares its own options + config)
  imports = [ ./services/llmster.nix ./services/openwebui.nix ./services/ollama.nix ];

  config = lib.mkIf cfg.enable {
    # Kernel tuning for inference workloads
    boot.kernel.sysctl = {
      "kernel.shmmax" = 34359738368;
      "kernel.shmall" = 8388608;
      "vm.swappiness" = 10;
    };
  };
}
