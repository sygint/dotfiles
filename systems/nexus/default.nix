# NixOS configuration for Nexus (Homelab)
# Purpose: Centralized homelab services including media, monitoring, and automation
{ config, pkgs, lib, hasSecrets, inputs, ... }:

let
  systemVars = import ./variables.nix;
  networkConfig = import ../../fleet-config.nix;
  inherit (systemVars.system) hostName;
  inherit (systemVars.user) username;
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix  # Disko configuration for nixos-anywhere
    ../../modules/system.nix
  ];

  # Essential boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking.hostName = hostName;
  time.timeZone = networkConfig.global.timeZone;

  # ===== NAS Storage Mounts =====
  # Mount Synology NAS media shares via NFS
  # NAS IP: 192.168.1.136
  # Nexus will use static IP: 192.168.1.20 (configure in UDM Pro DHCP reservations)
  fileSystems."/mnt/nas/movies" = {
    device = "192.168.1.136:/volume1/Media/Movies";
    fsType = "nfs";
    options = [ 
      "x-systemd.automount"  # Auto-mount on access
      "noauto"               # Don't mount at boot
      "x-systemd.idle-timeout=600"  # Unmount after 10min idle
      "nfsvers=4"            # Use NFSv4
    ];
  };

  fileSystems."/mnt/nas/tvshows" = {
    device = "192.168.1.136:/volume1/Media/TV Shows";
    fsType = "nfs";
    options = [ 
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "nfsvers=4"
    ];
  };

  fileSystems."/mnt/nas/music" = {
    device = "192.168.1.136:/volume1/Media/Music";
    fsType = "nfs";
    options = [ 
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "nfsvers=4"
    ];
  };

  # ===== User Configuration =====
  users.users.${username} = {
    isNormalUser = true;
    description = "Nexus Administrator";
    extraGroups = [ "wheel" "networkmanager" "jellyfin" "grafana" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
    ];
  };

  # Maintenance user for console/KVM emergency access only
  # This user CANNOT login via SSH (no keys, PasswordAuthentication disabled)
  # Use this account for physical console or KVM access when SSH is broken
  # TODO: Move password to sops after fixing age key configuration
  users.users.maintenance = {
    isNormalUser = true;
    description = "Console-only emergency maintenance account";
    hashedPassword = "$6$c5EF8P72vGv5Dize$cyxB5yReQzNXLVjZcdng7UuTLx9SA4oXGGHEtseUYdAH.yVBjALBz3RZd3u6mwlhgZh9wUT74yG6po7pOREch0";
    extraGroups = [ "wheel" ];  # Allows sudo
    # No SSH keys - console access only
  };

  # Ensure Jellyfin can read NAS mounts
  systemd.tmpfiles.rules = [
    "d /mnt/nas 0755 root root -"
    "d /mnt/nas/movies 0755 root root -"
    "d /mnt/nas/tvshows 0755 root root -"
    "d /mnt/nas/music 0755 root root -"
  ];

  # ===== Security Configuration =====
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.1"
      "192.168.1.0/24"  # Local network
    ];
  };

  # ===== Core Services =====
  
  # Jellyfin Media Server - Stream media from your NAS
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Prometheus - Collect system metrics
  services.prometheus = {
    enable = true;
    port = 9090;
    
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };

    scrapeConfigs = [
      {
        job_name = "nexus";
        static_configs = [{
          targets = [ 
            "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
          ];
        }];
      }
    ];
  };

  # Grafana - Visualize metrics with dashboards
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "nexus.home";
        root_url = "http://nexus.home:3000/";
      };
      security = {
        admin_user = "admin";
        admin_password = "admin"; # Change this on first login!
      };
    };
    
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
    };
  };

  # ===== Optional Services (disabled for now) =====
  # Uncomment these when you're ready to add them:
  
  # Home Assistant - Smart home automation
  # services.home-assistant = {
  #   enable = true;
  #   extraComponents = [ "esphome" "met" "radio_browser" ];
  #   config = {
  #     default_config = {};
  #     http = {
  #       server_host = "0.0.0.0";
  #       server_port = 8123;
  #     };
  #   };
  # };
  
  # Loki + Promtail - Log aggregation (like grep for all your logs)
  # services.loki.enable = true;
  # services.promtail.enable = true;

  # ===== Firewall Configuration =====
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22      # SSH
      3000    # Grafana
      8096    # Jellyfin HTTP
      8920    # Jellyfin HTTPS
      9090    # Prometheus (optional - can access via Grafana)
    ];
    allowedUDPPorts = [
      1900    # DLNA/UPnP discovery
      7359    # Jellyfin discovery
    ];
  };

  # ===== Module Configuration =====
  modules = {
    hardware = {
      bluetooth.enable = false;  # Headless server
      audio.enable = false;      # No local audio needed
      networking = {
        enable = true;
        hostName = "${hostName}";
      };
    };

    services = {
      syncthing = {
        enable = false;  # Enable if needed
      };

      printing = {
        enable = false;  # Headless server
      };
    };
  };

  # ===== Additional System Packages =====
  environment.systemPackages = with pkgs; [
    # Jellyfin packages
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    
    # Monitoring tools
    htop
    btop
    
    # Network tools
    iftop
    nethogs
    
    # System utilities
    tmux
    wget
    curl
    
    # Jellyfin utilities
    libva-utils  # Provides vainfo to check hardware video acceleration
  ];

  # ===== System State Version =====
  system.stateVersion = "24.11"; # Don't change this
}
