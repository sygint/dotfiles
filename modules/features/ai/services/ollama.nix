# Ollama — local LLM server + ollmcp MCP tooling
# Self-contained: options, service tweaks, firewall, packages
# ollama.enable implies ollmcp by default; disable explicitly if unwanted
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
  ocfg = cfg.ollama;
in
{
  options.modules.features.ai.ollama = {
    enable = lib.mkEnableOption "Enable Ollama server";
    ollmcp = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = ocfg.enable;
        description = "Enable ollmcp MCP client for Ollama (filesystem, git, web search tools). Defaults to ollama.enable.";
      };
    };
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Optional Nix package providing ollama binary";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 11434;
      description = "TCP port for Ollama API";
    };
  };

  config = lib.mkIf ocfg.enable {
    systemd.services.ollama = {
      serviceConfig = {
        Nice = -10;
        MemoryMax = "80%";
        CPUWeight = 100;
      };
    };

    networking.firewall.allowedTCPPorts = [ ocfg.port ];

    environment.systemPackages =
      [ pkgs.ollama ]
      ++ lib.optionals ocfg.ollmcp.enable [
        pkgs.uv
        pkgs.nodejs
        pkgs.git
        (pkgs.python3.withPackages (ps: [ ps.ollama ]))
      ];
  };
}
