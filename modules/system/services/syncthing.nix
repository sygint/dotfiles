{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.syncthing;
in
{
  options.modules.services.syncthing = {
    enable = mkEnableOption "Syncthing";

    username = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for the Syncthing";
    };

    password = lib.mkOption {
      type = lib.types.str;
      default = "password";
      description = "Password for the Syncthing";
    };
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        openDefaultPorts = true;
        settings.gui = {
          user = "${cfg.username}";
          password = "${cfg.password}";
        };
      };
    };
  };
}
