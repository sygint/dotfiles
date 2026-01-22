# Vaultwarden - Self-hosted Bitwarden compatible password manager
# https://github.com/dani-garcia/vaultwarden

{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers.containers.vaultwarden = {
    image = "vaultwarden/server:latest";
    autoStart = true;
    
    ports = [
      "8000:80"      # Web UI
      "3012:3012"    # WebSocket for real-time sync
    ];
    
    volumes = [
      "/var/lib/docker-data/vaultwarden:/data"
      "/mnt/synology/vaultwarden:/backups"
    ];
    
    environment = {
      # Domain configuration (update with your domain or Tailscale hostname)
      DOMAIN = "https://nexus";  # TODO: Update with actual domain
      
      # Security settings
      SIGNUPS_ALLOWED = "true";  # Set to false after creating your account
      INVITATIONS_ALLOWED = "true";
      SHOW_PASSWORD_HINT = "false";
      
      # Admin panel (optional - disable in production)
      # ADMIN_TOKEN = "CHANGE_ME";  # Run: openssl rand -base64 48
      
      # WebSocket for real-time sync
      WEBSOCKET_ENABLED = "true";
      WEBSOCKET_ADDRESS = "0.0.0.0";
      WEBSOCKET_PORT = "3012";
      
      # Performance
      ROCKET_WORKERS = "4";
      
      # Backup configuration
      # Vaultwarden will store data in /data, which is mounted to local SSD
      # We mount /backups to Synology for backup storage
    };
    
    extraOptions = [
      "--network=homelab"
    ];
  };

  # Automatic backup script
  systemd.services.vaultwarden-backup = {
    description = "Backup Vaultwarden data to Synology";
    after = [ "docker-vaultwarden.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    
    script = ''
      #!/bin/sh
      BACKUP_DIR="/mnt/synology/vaultwarden/backups"
      DATA_DIR="/var/lib/docker-data/vaultwarden"
      DATE=$(date +%Y%m%d_%H%M%S)
      
      # Create backup directory if it doesn't exist
      mkdir -p "$BACKUP_DIR"
      
      # Backup SQLite database
      if [ -f "$DATA_DIR/db.sqlite3" ]; then
        ${pkgs.sqlite}/bin/sqlite3 "$DATA_DIR/db.sqlite3" ".backup '$BACKUP_DIR/db_$DATE.sqlite3'"
        echo "Vaultwarden backup completed: $DATE"
      fi
      
      # Keep only last 30 days of backups
      find "$BACKUP_DIR" -name "db_*.sqlite3" -mtime +30 -delete
    '';
  };

  # Schedule daily backups at 2 AM
  systemd.timers.vaultwarden-backup = {
    description = "Daily Vaultwarden backup";
    wantedBy = [ "timers.target" ];
    
    timerConfig = {
      OnCalendar = "02:00";
      Persistent = true;
    };
  };
}
