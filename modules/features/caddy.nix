# Caddy reverse proxy module
# Provides friendly hostname-based access to services (no port numbers)
#
# Example:
#   modules.features.caddy = {
#     enable = true;
#     reverseProxies = {
#       "git.cortex.home"  = "localhost:3300";
#       "chat.cortex.home" = "localhost:8888";
#     };
#   };
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mapAttrs
    types
    ;

  cfg = config.modules.features.caddy;
in
{
  options.modules.features.caddy = {
    enable = mkEnableOption "Caddy reverse proxy for local services";

    reverseProxies = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "git.cortex.home" = "localhost:3300";
        "chat.cortex.home" = "localhost:8888";
      };
      description = ''
        Map of virtual hostnames to upstream addresses.
        Each entry creates a Caddy virtual host that reverse-proxies
        to the specified upstream (host:port).
      '';
    };
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;

      # Generate a virtualHost for each reverse proxy entry
      # Prefix with http:// to disable Caddy's automatic HTTPS
      # (local .home domains don't have public TLS certificates)
      virtualHosts = mapAttrs (hostname: upstream: {
        extraConfig = "reverse_proxy ${upstream}";
      }) (lib.mapAttrs' (hostname: upstream:
        lib.nameValuePair "http://${hostname}" upstream
      ) cfg.reverseProxies);
    };

    # Caddy needs port 80 (HTTP) open
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
