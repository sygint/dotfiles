{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  cfg = config.modules.features.vikunja;
in
{
  options.modules.features.vikunja = {
    enable = mkEnableOption "Vikunja project management";

    domain = mkOption {
      type = types.str;
      default = "projects.cortex.home";
      description = "Domain for Vikunja";
    };

    port = mkOption {
      type = types.port;
      default = 3456;
      description = "Port for Vikunja API";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/vikunja";
      description = "Data directory for Vikunja";
    };
  };

  config = mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      package = pkgs.vikunja;
      frontendScheme = "https";
      frontendHostname = cfg.domain;
      settings = {
        service = {
          publicURL = "https://${cfg.domain}/";
          enableEmailReminders = false;
          enableRegistration = false;
          enableTaskAttachments = true;
          enableTaskComments = true;
        };
        database = {
          type = "sqlite";
          path = "${cfg.dataDir}/vikunja.db";
        };
        log = {
          enabled = true;
          level = "INFO";
          path = "${cfg.dataDir}/logs";
        };
        files = {
          basepath = "${cfg.dataDir}/files";
        };
        ratelimit = {
          enabled = true;
          kind = "user";
          limit = 100;
          period = 60;
        };
      };
    };

    users.users.vikunja = {
      isSystemUser = true;
      group = "vikunja";
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.vikunja = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 vikunja vikunja - -"
      "d ${cfg.dataDir}/files 0750 vikunja vikunja - -"
      "d ${cfg.dataDir}/logs 0750 vikunja vikunja - -"
    ];
  };
}
