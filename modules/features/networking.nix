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
      # wireless.enable is intentionally left unset - NetworkManager's module manages wpa_supplicant as its backend.

      # NetworkManager-wait-online is unreliable (especially with WiFi) and causes nh to abort activation.
      networkmanager.wifi.powersave = false;

      # Enable firewall
      firewall = {
        enable = true;
        allowedTCPPorts = [ ]; # No TCP ports open to internet
      };
    };

    environment.systemPackages = with pkgs; [
      networkmanagerapplet # nm-connection-editor for advanced network settings
    ];

    # NetworkManager-wait-online is unreliable (especially with WiFi) and causes nh to abort activation.
    systemd.services.NetworkManager-wait-online.enable = false;

  };
}
