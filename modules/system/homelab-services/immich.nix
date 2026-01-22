# Immich - Self-hosted photo and video management solution
# https://immich.app/

{ config, pkgs, lib, ... }:

let
  immichVersion = "v1.122.3";  # Update regularly for new features
in
{
  # Immich requires multiple containers: server, machine-learning, redis, postgres
  
  virtualisation.oci-containers.containers = {
    # PostgreSQL database
    immich-postgres = {
      image = "tensorchord/pgvecto-rs:pg14-v0.2.0";
      autoStart = true;
      
      volumes = [
        "/var/lib/docker-data/immich/postgres:/var/lib/postgresql/data"
      ];
      
      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_PASSWORD = "immich";  # TODO: Change in production
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      
      extraOptions = [
        "--network=homelab"
      ];
    };

    # Redis cache
    immich-redis = {
      image = "redis:7-alpine";
      autoStart = true;
      
      extraOptions = [
        "--network=homelab"
      ];
    };

    # Immich server
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${immichVersion}";
      autoStart = true;
      dependsOn = [ "immich-postgres" "immich-redis" ];
      
      ports = [
        "2283:3001"  # Immich web UI
      ];
      
      volumes = [
        "/mnt/synology/immich:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      
      environment = {
        DB_HOSTNAME = "immich-postgres";
        DB_USERNAME = "immich";
        DB_PASSWORD = "immich";
        DB_DATABASE_NAME = "immich";
        
        REDIS_HOSTNAME = "immich-redis";
        
        # Upload settings
        UPLOAD_LOCATION = "/usr/src/app/upload";
        
        # Disable analytics (privacy)
        IMMICH_TELEMETRY_INCLUDE = "none";
        
        # Performance settings
        IMMICH_WORKERS_INCLUDE = "api";
      };
      
      extraOptions = [
        "--network=homelab"
      ];
    };

    # Immich machine learning (for face detection, object recognition)
    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
      autoStart = true;
      
      volumes = [
        "/var/lib/docker-data/immich/model-cache:/cache"
      ];
      
      environment = {
        # Machine learning settings
        MACHINE_LEARNING_WORKERS = "1";  # Adjust based on CPU
        MACHINE_LEARNING_WORKER_TIMEOUT = "120";
      };
      
      extraOptions = [
        "--network=homelab"
      ];
    };
  };

  # Ensure Immich data directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/docker-data/immich 0755 root root -"
    "d /var/lib/docker-data/immich/postgres 0755 root root -"
    "d /var/lib/docker-data/immich/model-cache 0755 root root -"
  ];
}
