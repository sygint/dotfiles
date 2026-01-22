{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.features.networking;
in
{
  options.modules.features.networking = {
    enable = mkEnableOption "NetworkManager networking support";

    hostName = mkOption {
      type = types.str;
      description = "System hostname";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = cfg.hostName;
      networkmanager.enable = true;

      # Enable firewall
      firewall = {
        enable = true;
        allowedTCPPorts = [ ]; # No TCP ports open to internet
      };
    };
  };
}
