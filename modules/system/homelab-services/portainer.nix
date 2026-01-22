# Portainer - Docker container management UI
# https://www.portainer.io/

{ config, pkgs, lib, ... }:

{
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce:latest";
    autoStart = true;
    
    ports = [
      "9000:9000"    # Web UI (HTTP)
      "9443:9443"    # Web UI (HTTPS)
    ];
    
    volumes = [
      "/var/lib/docker-data/portainer:/data"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
    
    extraOptions = [
      "--network=homelab"
      "--privileged"  # Required for Docker socket access
    ];
  };

  # Portainer provides a web UI to manage all your Docker containers
  # Access at http://nexus:9000 or https://nexus:9443
  # On first login, you'll create an admin account
  # 
  # From Portainer you can:
  # - View and manage all containers
  # - View logs
  # - Access container consoles
  # - Monitor resource usage
  # - Deploy new containers
}
