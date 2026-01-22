# Homelab Services Module
#
# Self-hosted services for Nexus:
# - Vaultwarden (Password Manager)
# - Immich (Photo Management)
# - Syncthing (File Sync)
# - Uptime Kuma (Monitoring)
# - Portainer (Docker Management UI)

{ config, pkgs, lib, ... }:

{
  imports = [
    ./vaultwarden.nix
    ./immich.nix
    ./syncthing.nix
    ./uptime-kuma.nix
    ./portainer.nix
  ];

  # Shared configuration for all homelab services
  
  # Create shared Docker network for services
  systemd.services.docker-homelab-network = {
    description = "Create Docker network for homelab services";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker}/bin/docker network create homelab || true";
      ExecStop = "${pkgs.docker}/bin/docker network rm homelab || true";
    };
  };

  # Ensure Docker data directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/docker-data 0755 root root -"
    "d /var/lib/docker-data/vaultwarden 0755 root root -"
    "d /var/lib/docker-data/immich 0755 root root -"
    "d /var/lib/docker-data/uptime-kuma 0755 root root -"
    "d /var/lib/docker-data/portainer 0755 root root -"
  ];
}
