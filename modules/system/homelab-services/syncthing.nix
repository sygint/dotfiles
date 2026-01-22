# Syncthing - Continuous file synchronization
# Perfect for Obsidian/Logseq note syncing
# https://syncthing.net/

{ config, pkgs, lib, ... }:

{
  # Using native NixOS Syncthing service instead of Docker for better integration
  services.syncthing = {
    enable = true;
    user = "admin";
    group = "users";
    
    # Data directory
    dataDir = "/mnt/synology/syncthing";
    configDir = "/var/lib/syncthing";
    
    # Web UI settings
    guiAddress = "0.0.0.0:8384";
    
    # Open firewall ports (already configured in default.nix but keeping here for reference)
    openDefaultPorts = true;
    
    # Syncthing settings
    settings = {
      options = {
        # Global discovery and relay
        globalAnnounceEnabled = true;
        localAnnounceEnabled = true;
        relaysEnabled = true;
        
        # NAT traversal
        natEnabled = true;
        
        # Performance
        maxSendKbps = 0;  # Unlimited
        maxRecvKbps = 0;  # Unlimited
        
        # Privacy
        urAccepted = -1;  # Disable usage reporting
      };
      
      # Example folder configuration (you'll add your actual folders via web UI)
      # folders = {
      #   "obsidian-vault" = {
      #     path = "/mnt/synology/syncthing/obsidian";
      #     devices = [ "orion" "phone" ];  # Add device IDs via web UI
      #     type = "sendreceive";
      #     fsWatcherEnabled = true;
      #     ignorePerms = false;
      #   };
      # };
      
      # Devices will be added via web UI
      # devices = {
      #   "orion" = {
      #     id = "DEVICE-ID-HERE";
      #   };
      # };
    };
  };

  # Ensure Syncthing data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/syncthing 0755 admin users -"
  ];
  
  # Note: After first startup, access web UI at http://nexus:8384
  # to configure devices and folders
}
