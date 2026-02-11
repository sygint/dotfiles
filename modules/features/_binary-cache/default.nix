# Binary Cache Module - Harmonia Nix Binary Cache
# Serves built derivations to other machines on the network
# so deploys pull from cache instead of rebuilding
#
# This module requires the harmonia NixOS module to be imported at the system
# level. Import it only on systems that have it (see flake-modules/lib.nix).
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

  cfg = config.modules.features.binary-cache;
in
{
  options.modules.features.binary-cache = {
    enable = mkEnableOption "Harmonia Nix binary cache server";

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port for the Harmonia binary cache server";
    };

    priority = mkOption {
      type = types.int;
      default = 30;
      description = "Cache priority (lower = preferred over higher priority caches)";
    };
  };

  config = mkIf cfg.enable {

    # ===== Secrets =====
    sops.secrets."nexus/harmonia_signing_key" = {
      owner = "harmonia";
      group = "harmonia";
      mode = "0400";
    };

    # ===== Harmonia Binary Cache =====
    services.harmonia = {
      enable = true;
      signKeyPaths = [
        config.sops.secrets."nexus/harmonia_signing_key".path
      ];
      settings = {
        bind = "0.0.0.0:${toString cfg.port}";
        priority = cfg.priority;
      };
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [
      cfg.port
    ];

    # Generate the signing key pair if it doesn't exist
    # Run this once manually on nexus:
    #   nix-store --generate-binary-cache-key nexus.home cache-priv-key.pem cache-pub-key.pem
    #   # Then add cache-priv-key.pem to sops secrets as nexus/harmonia_signing_key
    #   # And distribute cache-pub-key.pem to other machines via nix.settings.trusted-public-keys
  };
}
