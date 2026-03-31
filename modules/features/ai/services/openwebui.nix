{ config, lib, pkgs, ... }:
let
  cfg = config.modules.features.ai;
in
{
  config = lib.mkIf cfg.openWebui.enable {
    services.open-webui = {
      enable = true;
      host = cfg.openWebui.host or "0.0.0.0";
      port = cfg.openWebui.port or 8888;
      environment = {
        OLLAMA_API_BASE_URL = if cfg.llmster.enable then ''http://localhost:${toString cfg.llmster.port}'' else "http://localhost:11434";
        WEBUI_AUTH = "true";
        WEBUI_NAME = "Cortex AI - RTX 5090";
        ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "false";
      };
    };
  };
}
