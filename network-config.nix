# Network Configuration
# Single source of truth for all network hosts and infrastructure
#
# This file centralizes network configuration for:
# - IP addresses and hostnames
# - MAC addresses for Wake-on-LAN
# - SSH configuration
# - Deployment settings
#
# Benefits:
# - DRY: Define once, use everywhere
# - Type-safe: Nix ensures consistency
# - Easy updates: Change in one place
# - Scriptable: Generate scripts from this config
{
  # Network-wide settings
  network = {
    domain = "home";
    subnet = "192.168.1.0/24";
    gateway = "192.168.1.1";
    dns = [ "192.168.1.1" "1.1.1.1" ];
  };

  # Host configurations
  hosts = {
    # Orion - Primary laptop/workstation
    orion = {
      hostname = "orion";
      fqdn = "orion.home";
      ip = "192.168.1.100";  # Update with actual IP if static
      
      # Network interfaces
      interfaces = {
        wifi = {
          name = "wlp1s0";  # May vary based on hardware
          mac = null;  # WiFi MAC not typically needed
        };
        ethernet = {
          name = "enp0s0";  # May vary - check with `ip link`
          mac = null;  # Update if you want WoL for orion
        };
      };
      
      # SSH configuration
      ssh = {
        user = "syg";
        port = 22;
        keyPath = "~/.ssh/id_ed25519";
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos";
      };
      
      # Wake-on-LAN configuration
      wol = {
        enabled = false;  # Typically not needed for primary workstation
        interface = null;
        mac = null;
      };
      
      # Deployment configuration
      deploy = {
        enabled = false;  # Orion is the control machine, not a deploy target
        remoteBuild = false;
      };
    };

    # Cortex - AI/ML server
    cortex = {
      hostname = "cortex";
      fqdn = "cortex.home";
      ip = "192.168.1.7";
      
      # Network interfaces
      interfaces = {
        ethernet = {
          name = "enp3s0";
          mac = "9c:6b:00:35:51:55";  # Required for Wake-on-LAN
        };
      };
      
      # SSH configuration
      ssh = {
        user = "jarvis";
        port = 22;
        keyPath = "~/.ssh/id_ed25519";
        # Authorized keys that can access this host
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
        ];
      };
      
      # Wake-on-LAN configuration
      wol = {
        enabled = true;
        interface = "enp3s0";
        mac = "9c:6b:00:35:51:55";
      };
      
      # Deployment configuration
      deploy = {
        enabled = true;
        remoteBuild = true;  # Build on remote to avoid signature issues
        method = "deploy-rs";
      };
    };

    # Template for adding new hosts
    # Copy this block and customize for each new machine
    #
    # hostname-here = {
    #   hostname = "hostname";
    #   fqdn = "hostname.home";
    #   ip = "192.168.1.x";
    #   
    #   interfaces = {
    #     ethernet = {
    #       name = "enp0s0";
    #       mac = "xx:xx:xx:xx:xx:xx";
    #     };
    #   };
    #   
    #   ssh = {
    #     user = "username";
    #     port = 22;
    #     keyPath = "~/.ssh/id_ed25519";
    #     publicKey = "ssh-ed25519 ...";
    #     authorizedKeys = [ ];
    #   };
    #   
    #   wol = {
    #     enabled = false;
    #     interface = null;
    #     mac = null;
    #   };
    #   
    #   deploy = {
    #     enabled = false;
    #     remoteBuild = false;
    #     method = "deploy-rs";
    #   };
    # };
  };
}
