{ config, lib, pkgs, ... }:
let
  cfg = config.modules.features.ai;
in
{
  config = lib.mkIf cfg.enableOllmcp {
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
