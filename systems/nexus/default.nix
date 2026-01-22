# NixOS configuration for Nexus (Homelab)
# Purpose: Centralized homelab services including media, monitoring, and automation
{
  config,
  pkgs,
  lib,
  hasSecrets,
  inputs,
  ...
}:

let
  systemVars = import ./variables.nix;
  networkConfig = import ../../fleet-config.nix;
  inherit (systemVars.system) hostName;
  inherit (systemVars.user) username;
in
{
  imports = [
    ./hardware.nix
    ./disk-config.nix
    ../../modules/system.nix
    ../../modules/features.nix
  ]
  ++ lib.optionals hasSecrets [
    (import (inputs.nixos-secrets + "/default.nix") {
      inherit
        config
        lib
        pkgs
        inputs
        hasSecrets
        ;
    })
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

  # ===== Secrets Management =====
  # Secrets are mandatory for this system
  assertions = [
    {
      assertion = hasSecrets;
      message = "Secrets required—nixos-secrets submodule missing";
    }
  ];

  # The nixos-secrets module already sets defaultSopsFile, just configure what we need here
  sops = {
    age.keyFile = lib.mkForce "/var/lib/sops-nix/key.txt"; # Override to use dedicated key file

    secrets."nexus/rescue_password_hash" = {
      neededForUsers = true;
    };
    # Leantime environment files for containers (loaded at runtime by Podman)
    # These files contain MYSQL_PASSWORD and MYSQL_ROOT_PASSWORD for DB
    # and LEAN_DB_PASSWORD for the app container
    secrets."nexus/leantime_db_env" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
    secrets."nexus/leantime_app_env" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    secrets."nexus/grafana_admin_password" = {
      owner = "grafana";
      group = "grafana";
    };
  };

  # ===== NAS Storage Mounts =====
  # Mount Synology NAS media shares via NFS
  # NAS IP: 192.168.1.136
  # Nexus will use static IP: 192.168.1.20 (configure in UDM Pro DHCP reservations)
  fileSystems."/mnt/nas/movies" = {
    device = "192.168.1.136:/volume1/Media/Movies";
    fsType = "nfs";
    options = [
      "x-systemd.automount" # Auto-mount on access
      "noauto" # Don't mount at boot
      "x-systemd.idle-timeout=600" # Unmount after 10min idle
      "nfsvers=4" # Use NFSv4
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

  # Deploy user: SSH-only for remote deployments (key-only, no password)
  users.users.${username} = {
    isNormalUser = true;
    description = "Remote deployment user (SSH key-only)";
    extraGroups = [
      "wheel"
      "networkmanager"
      "jellyfin"
      "grafana"
    ];
    # SSH: Key-only authentication (no password set)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
    ];
    # Password is explicitly locked - this user CANNOT login at console
    # This provides clear separation: SSH uses this user, console uses rescue user
    # Passwordless sudo via security.sudo.wheelNeedsPassword = false
    hashedPassword = "!"; # Locked account - SSH key only
  };

  # Rescue user: Console-only for physical/KVM emergency access (password-only, no SSH)
  users.users.rescue = {
    isNormalUser = true;
    description = "Emergency console access (password-only)";
    extraGroups = [ "wheel" ]; # Can sudo for system repairs
    # Password for console/KVM access via secrets
    hashedPasswordFile = config.sops.secrets."nexus/rescue_password_hash".path;
    # No SSH keys - this user CANNOT login remotely
    # Provides audit trail: rescue user = physical access only
  };

  # ===== Nix Configuration =====
  # Deploy user needs to be trusted for remote deployments
  nix.settings = {
    trusted-users = [
      "root"
      "deploy"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Ensure Jellyfin can read NAS mounts

  # ===== Security Configuration =====

  # Passwordless sudo for wheel group (needed for remote deployments)
  # Override the security module's default of requiring passwords
  security.sudo.wheelNeedsPassword = lib.mkForce false;

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
      "192.168.1.0/24" # Local network
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
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
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
        admin_password_file = config.sops.secrets."nexus/grafana_admin_password".path;
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

  # Create required directories for Leantime data persistence
  # Leantime storage directories
  # UID/GID 1000 = www-data inside the leantime container
  # These directories MUST exist before the container starts
  systemd.tmpfiles.rules = [
    # NAS mounts
    "d /mnt/nas 0755 root root -"
    "d /mnt/nas/movies 0755 root root -"
    "d /mnt/nas/tvshows 0755 root root -"
    "d /mnt/nas/music 0755 root root -"
    # Leantime storage
    "d /var/lib/leantime 0755 root root -"
    "d /var/lib/leantime/db-data 0755 root root -"
    "d /var/lib/leantime/userfiles 0755 1000 1000 -"
    "d /var/lib/leantime/plugins 0755 1000 1000 -"
    "d /var/lib/leantime/storage 0755 1000 1000 -"
    "d /var/lib/leantime/storage/logs 0755 1000 1000 -"
    "d /var/lib/leantime/storage/app 0755 1000 1000 -"
    "d /var/lib/leantime/storage/debugbar 0755 1000 1000 -"
    "d /var/lib/leantime/storage/framework 0755 1000 1000 -"
    "d /var/lib/leantime/storage/framework/cache 0755 1000 1000 -"
    "d /var/lib/leantime/storage/framework/cache/data 0755 1000 1000 -"
    "d /var/lib/leantime/storage/framework/cache/installation 0755 1000 1000 -"
    "d /var/lib/leantime/storage/framework/sessions 0755 1000 1000 -"
    "d /var/lib/leantime/storage/framework/views 0755 1000 1000 -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # Leantime - Goals-focused PM tool (https://leantime.io/)
      leantime-db = {
        image = "mariadb:10.11";
        ports = [ ]; # Not exposed outside
        volumes = [
          "/var/lib/leantime/db-data:/var/lib/mysql"
        ];
        environment = {
          MYSQL_DATABASE = "leantime";
          MYSQL_USER = "leantime";
          # Passwords loaded from environmentFiles below
        };
        environmentFiles = [
          config.sops.secrets."nexus/leantime_db_env".path
        ];
        autoStart = true;
      };
      leantime = {
        image = "leantime/leantime:latest";
        ports = [ "8080:8080" ];
        volumes = [
          "/var/lib/leantime/userfiles:/var/www/html/userfiles"
          "/var/lib/leantime/plugins:/var/www/html/app/Plugins"
          "/var/lib/leantime/storage:/var/www/html/storage"
        ];
        environment = {
          LEAN_DB_HOST = "leantime-db";
          LEAN_DB_USER = "leantime";
          LEAN_DB_DATABASE = "leantime";
          LEAN_EMAIL_RETURN = "no-reply@localhost";
          LEAN_APP_URL = "http://nexus.home:8080"; # Use flake DNS/hostname instead of localhost
          # Password loaded from environmentFiles below
        };
        environmentFiles = [
          config.sops.secrets."nexus/leantime_app_env".path
        ];
        dependsOn = [ "leantime-db" ];
        autoStart = true;
      };
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
      22 # SSH
      3000 # Grafana
      8080 # Leantime
      8096 # Jellyfin HTTP
      8920 # Jellyfin HTTPS
      9090 # Prometheus (optional - can access via Grafana)
    ];
    allowedUDPPorts = [
      1900 # DLNA/UPnP discovery
      7359 # Jellyfin discovery
    ];
  };

  # ===== Module Configuration =====
  modules = {
    hardware = {
      bluetooth.enable = false; # Headless server
      audio.enable = false; # No local audio needed
      networking = {
        enable = true;
        hostName = "${hostName}";
      };
    };

    services = {
      containerization.enable = true; # Podman for OCI containers

      syncthing = {
        enable = false; # Enable if needed
      };

      printing = {
        enable = false; # Headless server
      };
    };

    system.security = {
      enable = true; # Enable security module (sudo, polkit, etc.)
      hardening.enable = true; # Full server hardening profile (fail2ban, auditd, SSH, kernel, monitoring)
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
    sqlite

    # Jellyfin utilities
    libva-utils # Provides vainfo to check hardware video acceleration
  ];

  # ===== System State Version =====
  system.stateVersion = "24.11"; # Don't change this
}
