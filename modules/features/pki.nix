# PKI — Fleet-wide Certificate Authority trust and server TLS certificates
#
# Provides two functions:
#   1. CA trust: installs the fleet CA cert into the system trust store
#      so all browsers and tools trust *.home services (all machines)
#   2. Server certs: deploys TLS cert+key for hosts that serve HTTPS
#      (only on machines running Caddy/nginx/etc.)
#
# The CA cert is public and lives in the nix repo (certs/ca.crt).
# Private keys are stored encrypted in sops-nix and decrypted at boot.
#
# Usage:
#   # All machines (trust the CA):
#   modules.features.pki.enable = true;
#
#   # Machines serving HTTPS (e.g. cortex):
#   modules.features.pki = {
#     enable = true;
#     serverCert = {
#       certFile = ../../certs/cortex.crt;
#       keySecret = "pki/cortex_key";  # sops secret name
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
    types
    ;

  cfg = config.modules.features.pki;
in
{
  options.modules.features.pki = {
    enable = mkEnableOption "Fleet PKI — CA trust and optional server TLS certificates";

    caCertFile = mkOption {
      type = types.path;
      default = ../../certs/ca.crt;
      description = "Path to the fleet CA certificate (public, in the nix repo).";
    };

    serverCert = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          certFile = mkOption {
            type = types.path;
            description = "Path to the server certificate (public, in the nix repo).";
          };
          keySecret = mkOption {
            type = types.str;
            description = "sops secret name for the server private key (e.g. 'pki/cortex_key').";
          };
        };
      });
      default = null;
      description = ''
        Server TLS certificate configuration.
        When set, the cert and decrypted key are made available for Caddy/nginx.
        The key is decrypted by sops-nix at boot and placed at a known path.
      '';
    };
  };

  config = mkIf cfg.enable {
    # 1. Trust the fleet CA on this machine
    # This works for Chrome, curl, and most apps that use the system store.
    security.pki.certificateFiles = [ cfg.caCertFile ];

    # 2. Deploy server cert + key (only when serverCert is configured)
    sops.secrets = mkIf (cfg.serverCert != null) {
      ${cfg.serverCert.keySecret} = {
        owner = "caddy";
        group = "caddy";
        mode = "0400";
        restartUnits = [ "caddy.service" ];
      };
    };

    # Make the server cert available at a stable path for Caddy
    # The cert is public so we just symlink it; the key comes from sops.
    environment.etc = mkIf (cfg.serverCert != null) {
      "pki/server.crt".source = cfg.serverCert.certFile;
    };
  };
}
