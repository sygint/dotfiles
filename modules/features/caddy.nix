# Caddy reverse proxy module
# Provides friendly hostname-based access to services (no port numbers)
#
# Without TLS:
#   Serves HTTP only on port 80
#
# With TLS (when PKI server cert is configured):
#   Serves HTTPS on port 443 with the fleet CA-signed certificate
#   Also serves HTTP on port 80 (no forced redirect, for API compat)
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
    mkMerge
    types
    ;

  cfg = config.modules.features.caddy;
  pkiCfg = config.modules.features.pki;

  # TLS is available when PKI module provides a server cert
  hasTLS = pkiCfg.enable && pkiCfg.serverCert != null;

  # Build HTTP virtualHosts (always present)
  httpHosts = lib.mapAttrs' (hostname: upstream:
    lib.nameValuePair "http://${hostname}" {
      extraConfig = "reverse_proxy ${upstream}";
    }
  ) cfg.reverseProxies;

  # HTTPS host builder — only called when hasTLS is true
  mkHttpsHosts = certPath: keyPath:
    lib.mapAttrs' (hostname: upstream:
      lib.nameValuePair "https://${hostname}" {
        extraConfig = ''
          tls ${certPath} ${keyPath}
          reverse_proxy ${upstream}
        '';
      }
    ) cfg.reverseProxies;
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

  config = mkIf cfg.enable (mkMerge [
    # Always: HTTP on port 80
    {
      services.caddy = {
        enable = true;
        virtualHosts = httpHosts;
      };
      networking.firewall.allowedTCPPorts = [ 80 ];
    }

    # When TLS available: add HTTPS on port 443
    (mkIf hasTLS (
      let
        certPath = "/etc/pki/server.crt";
        keyPath = config.sops.secrets.${pkiCfg.serverCert.keySecret}.path;
      in
      {
        services.caddy.virtualHosts = mkHttpsHosts certPath keyPath;
        networking.firewall.allowedTCPPorts = [ 443 ];
      }
    ))
  ]);
}
