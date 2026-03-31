{ config, lib, pkgs, ... }:
let
  cfg = config.modules.features.ai-services;
in
{
  config = lib.mkIf cfg.enableOllmcp {
    # Keep existing ollama overrides (serviceConfig tweaks)
    systemd.services.ollama = lib.mkIf cfg.enableOllmcp {
      serviceConfig = {
        Nice = -10;
        MemoryMax = "80%";
        CPUWeight = 100;
      };
    };
    environment.systemPackages = lib.optionals cfg.enableOllmcp [ pkgs.ollama ];
  };
}
