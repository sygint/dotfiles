# Open WebUI — web frontend for local LLM inference
# Self-contained: options, service config, firewall, API target resolution
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
  ocfg = cfg.openWebui;
  # Precedence: llmster > ollama > disabled
  apiTarget =
    if cfg.llmster.enable
    then "http://localhost:${toString cfg.llmster.port}"
    else if cfg.ollama.enable
    then "http://localhost:${toString cfg.ollama.port}"
    else "";
in
{
  options.modules.features.ai.openWebui = {
    enable = lib.mkEnableOption "Enable Open WebUI service";
    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host address for Open WebUI to bind to";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8888;
      description = "TCP port for Open WebUI";
    };
  };

  config = lib.mkIf ocfg.enable {
    services.open-webui = {
      enable = true;
      host = ocfg.host;
      port = ocfg.port;
      environment = {
        OLLAMA_API_BASE_URL = apiTarget;
        WEBUI_AUTH = "true";
        WEBUI_NAME = "Cortex AI - RTX 5090";
        ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "false";
      };
    };

    networking.firewall.allowedTCPPorts = [ ocfg.port ];
  };
}
