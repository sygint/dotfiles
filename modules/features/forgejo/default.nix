# Forgejo Module - Self-hosted Git Forge
# Lightweight Gitea fork for self-hosted code hosting
# Integrates with buildbot-nix for CI/CD
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

  cfg = config.modules.features.forgejo;
in
{
  options.modules.features.forgejo = {
    enable = mkEnableOption "Forgejo self-hosted git forge";

    domain = mkOption {
      type = types.str;
      default = "forgejo.home";
      description = "Domain name for the Forgejo instance";
    };

    httpPort = mkOption {
      type = types.port;
      default = 3300;
      description = "HTTP port for the Forgejo web interface";
    };

    sshPort = mkOption {
      type = types.port;
      default = 3022;
      description = "SSH port for git operations (separate from system SSH)";
    };
  };

  config = mkIf cfg.enable {

    services.forgejo = {
      enable = true;

      # Database - use SQLite for simplicity on a homelab
      # PostgreSQL is also available if you need more performance
      database.type = "sqlite3";

      settings = {
        DEFAULT = {
          APP_NAME = "Nexus Forge";
        };

        server = {
          DOMAIN = cfg.domain;
          HTTP_PORT = cfg.httpPort;
          ROOT_URL = "http://${cfg.domain}/";
          # Use a separate SSH port to avoid conflict with system SSH
          SSH_PORT = cfg.sshPort;
          START_SSH_SERVER = true;
          SSH_LISTEN_PORT = cfg.sshPort;
        };

        # Disable public registration - admin creates accounts
        service = {
          DISABLE_REGISTRATION = true;
          REQUIRE_SIGNIN_VIEW = false;
        };

        # Session settings
        session = {
          COOKIE_SECURE = false; # Set to true if using HTTPS
        };

        # Repository defaults
        repository = {
          DEFAULT_BRANCH = "main";
        };

        # Webhook settings (needed for buildbot-nix integration)
        webhook = {
          ALLOWED_HOST_LIST = "loopback"; # Allow webhooks to localhost (buildbot)
        };

        # Actions - disable since we use buildbot-nix
        actions = {
          ENABLED = false;
        };
      };
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      cfg.httpPort # Web UI
      cfg.sshPort # Git SSH
    ];
  };
}
