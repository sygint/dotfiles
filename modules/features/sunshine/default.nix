{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.sunshine;
in
{
  options.modules.features.sunshine = mkEnableOption "Sunshine game streaming server";

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      layout = "us";
    };

    services.sunshine = {
      enable = true;
      openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      sunshine
    ];
  };
}
