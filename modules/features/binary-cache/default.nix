# Binary Cache Module - Simple Nix Binary Cache
# Serves built derivations to other machines on the network
# so deploys pull from cache instead of rebuilding
#
# This is a simplified version that runs without cryptographic signing
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
    enable = mkEnableOption "Simple Nix binary cache server";

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port for the binary cache server";
    };

    priority = mkOption {
      type = types.int;
      default = 30;
      description = "Cache priority (lower = preferred over higher priority caches)";
    };
  };

  config = mkIf cfg.enable {
    # ===== Simple Binary Cache =====
    # Using a simple HTTP server approach instead of Harmonia
    # For now, we'll disable this module since Harmonia is removed
    # and we don't have a replacement implemented yet
  };
}
