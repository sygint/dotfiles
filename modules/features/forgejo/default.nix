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

    adminUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Admin username to provision on first deploy";
    };

    adminEmail = mkOption {
      type = types.str;
      default = "admin@localhost";
      description = "Admin email address";
    };

    adminPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing admin password (sops secret)";
    };

    sshKeys = mkOption {
      type = types.listOf (types.submodule {
        options = {
          user = mkOption { type = types.str; description = "Forgejo username"; };
          name = mkOption { type = types.str; description = "Key label"; };
          publicKeyFile = mkOption { type = types.path; description = "Path to public key file (sops secret)"; };
        };
      });
      default = [];
      description = "SSH public keys to register in Forgejo (managed via sops)";
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
          ROOT_URL = "https://${cfg.domain}/";
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

    # Admin user + SSH key provisioning (runs after Forgejo starts)
    systemd.services.forgejo-provision = mkIf (cfg.adminUser != null) {
      description = "Provision Forgejo admin user and SSH keys";
      after = [ "forgejo.service" "sops-nix.service" ];
      requires = [ "forgejo.service" ];
      wants = [ "sops-nix.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "forgejo";
        Group = "forgejo";
      };
      path = [ config.services.forgejo.package pkgs.curl pkgs.jq ];
      environment = {
        FORGEJO_WORK_DIR = "/var/lib/forgejo";
      };
      script = let
        forgejoCmd = "forgejo --config /var/lib/forgejo/custom/conf/app.ini";
        apiBase = "http://localhost:${toString cfg.httpPort}/api/v1";
      in ''
        set -euo pipefail

        # Wait for Forgejo to be ready
        for i in $(seq 1 30); do
          ${forgejoCmd} admin user list >/dev/null 2>&1 && break
          sleep 1
        done

        # Create admin user if it doesn't exist
        if ! ${forgejoCmd} admin user list 2>/dev/null | grep -q '${cfg.adminUser}'; then
          ${forgejoCmd} admin user create \
            --username '${cfg.adminUser}' \
            --email '${cfg.adminEmail}' \
            --password "$(cat ${cfg.adminPasswordFile})" \
            --admin \
            --must-change-password=false
          echo "Created admin user: ${cfg.adminUser}"
        fi

        # Generate a temporary API token for key provisioning
        TOKEN=$(${forgejoCmd} admin user generate-access-token \
          --username '${cfg.adminUser}' \
          --token-name "provision-$(date +%s)" \
          --scopes write:admin \
          --raw)

        ${lib.concatMapStringsSep "\n" (key: ''
          # Register SSH key: ${key.name}
          PUB_KEY="$(cat ${key.publicKeyFile})"
          # Check if key already registered (by fingerprint)
          EXISTING=$(curl -sf -H "Authorization: token $TOKEN" \
            "${apiBase}/admin/users/${key.user}/keys" | jq -r '.[].fingerprint')
          KEY_FP=$(ssh-keygen -lf ${key.publicKeyFile} | awk '{print $2}')
          if ! echo "$EXISTING" | grep -qF "$KEY_FP"; then
            curl -sf -X POST "${apiBase}/admin/users/${key.user}/keys" \
              -H "Authorization: token $TOKEN" \
              -H "Content-Type: application/json" \
              -d "{\"key\": \"$PUB_KEY\", \"title\": \"${key.name}\"}"
            echo "Registered SSH key '${key.name}' for ${key.user}"
          else
            echo "SSH key '${key.name}' already registered for ${key.user}"
          fi
        '') cfg.sshKeys}
      '';
    };
  };
}
