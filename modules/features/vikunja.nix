# Vikunja Module - Self-hosted Project Management
# Full-featured PM with projects, milestones, deadlines, priorities, tags,
# kanban/list/Gantt views, and progress tracking.
# Uses SQLite by default (no external database required).
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

  cfg = config.modules.features.vikunja;
in
{
  options.modules.features.vikunja = {
    enable = mkEnableOption "Vikunja self-hosted project management";

    domain = mkOption {
      type = types.str;
      default = "projects.home";
      description = "Domain name for the Vikunja instance (used as public URL)";
    };

    port = mkOption {
      type = types.port;
      default = 3456;
      description = "HTTP port for the Vikunja API and web interface";
    };

    enableRegistration = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to allow public user registration (disable after creating admin account)";
    };
  };

  config = mkIf cfg.enable {
    services.vikunja = {
      enable = true;

      # Network binding
      # Bind to localhost only — all access goes through Caddy reverse proxy
      address = "127.0.0.1";
      port = cfg.port;

      # Public URL configuration
      frontendScheme = "https";
      frontendHostname = cfg.domain;

      # Database - SQLite for simplicity (no external DB needed)
      database = {
        type = "sqlite";
        path = "/var/lib/vikunja/vikunja.db";
      };

      # Application settings
      # See: https://vikunja.io/docs/config-options/
      settings = {
        service = {
          enableregistration = cfg.enableRegistration;
          enabletaskattachments = true;
          enabletaskcomments = true;
          enableemailreminders = false; # No mail server configured
        };

        # Rate limiting for API
        ratelimit = {
          enabled = true;
          kind = "user";
          period = 60;
          limit = 100;
        };

        # Logging
        log = {
          enabled = true;
          path = "/var/lib/vikunja/logs";
          standard = "stdout";
          level = "INFO";
        };
      };
    };

    # Open firewall port
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
