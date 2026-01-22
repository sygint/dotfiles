# Uptime Kuma - Self-hosted monitoring tool
# https://github.com/louislam/uptime-kuma

{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:latest";
    autoStart = true;
    
    ports = [
      "3001:3001"  # Web UI
    ];
    
    volumes = [
      "/var/lib/docker-data/uptime-kuma:/app/data"
    ];
    
    environment = {
      # Timezone
      TZ = "America/New_York";  # TODO: Update to your timezone
    };
    
    extraOptions = [
      "--network=homelab"
    ];
  };

  # Uptime Kuma doesn't need much configuration
  # After startup, access web UI at http://nexus:3001
  # and configure monitors for:
  # - Vaultwarden (http://nexus:8000)
  # - Immich (http://nexus:2283)
  # - Syncthing (http://nexus:8384)
  # - Portainer (http://nexus:9000)
  # - External services you care about
}
