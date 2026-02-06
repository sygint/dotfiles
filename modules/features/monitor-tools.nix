{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.monitor-tools;
  scriptSrc = ./../../scripts/desktop/monitor-setup.sh;
in
{
  options.modules.features.monitor-tools.enable =
    mkEnableOption "Monitor tools and scripts globally available";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "monitor-setup" (builtins.readFile scriptSrc))
      pkgs.jq
    ];
  };
}
