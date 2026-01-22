# Axon Media Center NixOS Configuration
# Optimized for streaming from Jellyfin server on Synology NAS

{
  config,
  pkgs,
  inputs,
  fh,
  lib,
  hasSecrets,
  ...
}:
let
  systemVars = import ./variables.nix;
  fleetConfig = import ../../fleet-config.nix;
  inherit (systemVars.system) hostName;
  inherit (systemVars.user) username;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    # Import base system configuration
    ../../modules/system/base
    # Import all other system modules
    ../../modules/system.nix
    # Import unified feature modules
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

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      userVars = systemVars.user;
    };
    users = {
      axon = import ./homes/axon.nix; # Admin user configuration (now axon)
      kiosk = import ./homes/kiosk.nix; # Kiosk user configuration
    };
  };

  boot = {
    supportedFilesystems = [
      "ntfs"
      "exfat"
    ];
    # Quiet boot for Axon
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    # Plymouth for boot splash screen
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  # Set your time zone.
  # Timezone from fleet config
  time.timeZone = systemVars.system.timeZone;

  # Enable hardware video acceleration for media playback
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Hardware video acceleration
      mesa
      libva
      libva-utils
      libva-vdpau-driver
      libvdpau-va-gl
      # Intel specific (if Intel graphics)
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  # Audio configuration optimized for Axon
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # User configuration
  users.users.axon = {
    isNormalUser = true;
    description = "axon";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
    ];
    shell = pkgs.zsh;
    # Set a password hash for admin access when needed
    # hashedPassword = "$6$..."; # Generate with: mkpasswd -m sha-512
    # For testing/VM: simple password (change in production!)
    initialPassword = "admin";
  };

  # Dedicated kiosk user for media playback (more secure)
  users.users.kiosk = {
    isNormalUser = true;
    description = "Axon Kiosk User";
    extraGroups = [
      "audio"
      "video"
    ];
    shell = pkgs.bash;
    # Empty password for auto-login to work (GDM requirement)
    # In production, consider using initialPassword instead
    initialPassword = "";
  };

  environment.shells = with pkgs; [
    zsh
    bash
  ];

  # Security: Require password for admin operations
  security.sudo.wheelNeedsPassword = true;

  # Network configuration with Jellyfin server access
  networking.extraHosts = ''
    ${fleetConfig.hosts.cortex.ip} cortex.home cortex
    ${fleetConfig.infrastructure.nas.ip} ${fleetConfig.infrastructure.nas.fqdn} ${fleetConfig.infrastructure.nas.hostname}
  '';

  modules = {
    features = {
      # Hardware
      bluetooth.enable = true;
      audio.enable = true;
      networking = {
        enable = true;
        hostName = "${hostName}";
      };
      # Display server
      wayland.enable = true;
      # Services
      printing = {
        enable = false; # Usually not needed for Axon
        enableAutoDiscovery = false;
        enableSharing = false;
      };
      # Core features
      zsh.enable = true;
      # Hyprland disabled - using GNOME for Axon simplicity
      hyprland.enable = false;
    };
  };

  # Display manager configuration optimized for Axon
  services = {
    xserver = {
      enable = true;
    };

    displayManager = {
      gdm = {
        enable = true;
        autoSuspend = false; # Prevent auto-suspend on Axon
      };
      autoLogin = {
        enable = true;
        user = "kiosk";
      };
    };

    desktopManager.gnome.enable = true;

    # Disable GNOME tracker for performance
    gnome.tinysparql.enable = false;
    gnome.localsearch.enable = false;
  };

  # Kiosk mode service - launches Jellyfin directly on boot
  systemd.services.jellyfin-kiosk = {
    description = "Jellyfin Media Player Kiosk Mode";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "exec";
      User = "kiosk";
      Group = "users";

      # Environment for Wayland/X11 compatibility
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/1001" # kiosk user UID
        "WAYLAND_DISPLAY=wayland-1"
        "DISPLAY=:0"
        "XDG_SESSION_TYPE=wayland"
      ];

      # Launch Jellyfin in TV/kiosk mode
      ExecStart = "${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer --fullscreen --tv";

      # Restart policy for robustness
      Restart = "always";
      RestartSec = "3";

      # Security restrictions for kiosk user
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;

      # Only allow access to necessary paths
      ReadWritePaths = [
        "/home/kiosk"
        "/tmp"
      ];

      # Additional security
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };

  # Enable the kiosk service for the kiosk user session
  systemd.user.services.jellyfin-kiosk = {
    description = "Jellyfin Media Player Kiosk Mode (User Service)";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.jellyfin-media-player}/bin/jellyfinmediaplayer --fullscreen --tv";
      Restart = "always";
      RestartSec = "3";
    };
  };

  # Workaround for GNOME autologin - required for GDM auto-login to work
  systemd.services = {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };

  # Power management for Axon
  powerManagement = {
    enable = true;
    # Prevent sleep when streaming
    powertop.enable = false;
  };

  # Disable unnecessary services for Axon
  services.gnome = {
    evolution-data-server.enable = lib.mkForce false;
    gnome-online-accounts.enable = lib.mkForce false;
    gnome-user-share.enable = lib.mkForce false;
  };

  # Remote control support (disabled for VM testing, enable for physical deployment)
  # services.lirc.enable = true;

  # CEC (Consumer Electronics Control) support for TV integration
  services.udev.extraRules = ''
    # CEC device access
    SUBSYSTEM=="cec", GROUP="video", MODE="0664"
    # IR receiver access
    KERNEL=="lirc*", GROUP="dialout", MODE="0664"
  '';

  # Axon-specific packages
  environment.systemPackages = with pkgs; [
    # Core Axon applications
    jellyfin-media-player # Primary Jellyfin client
    kodi # Alternative media center
    vlc # Versatile media player
    mpv # Lightweight media player

    # Streaming clients
    firefox # For web-based streaming
    # chromium               # Alternative browser (disabled for VM testing - huge build)

    # Media utilities
    mediainfo # Media file information
    ffmpeg # Media conversion
    yt-dlp # YouTube downloader

    # Remote control and automation
    libcec # CEC library (includes cec-client utilities)

    # Network tools
    nfs-utils # For NFS shares
    cifs-utils # For SMB/CIFS shares

    # System utilities for admin access
    htop # System monitor
    tree # Directory listing
    wget # Download utility
    curl # HTTP client

    # File management
    nemo-with-extensions # File manager

    # Kiosk management utilities
    (pkgs.writeShellScriptBin "kiosk-admin" ''
      # Switch to axon user from kiosk
      echo "Switching to axon user..."
      sudo -u axon -i
    '')

    (pkgs.writeShellScriptBin "kiosk-restart" ''
      # Restart kiosk service
      systemctl --user restart jellyfin-kiosk
    '')
  ];

  # Allow unfree packages for media applications
  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "kodi"
        "jellyfin-media-player"
        # "chrome"
        # "chromium"
      ];
    # Allow insecure packages (qtwebengine needed for Jellyfin Media Player)
    permittedInsecurePackages = [
      "qtwebengine-5.15.19"
    ];
  };

  # Network shares for accessing NAS content
  fileSystems = {
    # Example NFS mount for Jellyfin media
    # Uncomment and adjust path/server as needed
    # "/mnt/jellyfin" = {
    #   device = "synology.home:/volume1/jellyfin";
    #   fsType = "nfs";
    #   options = [ "rw" "hard" "intr" "rsize=8192" "wsize=8192" "timeo=14" ];
    # };
  };

  # Firewall configuration for media streaming
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      8096 # Jellyfin
      8920 # Jellyfin HTTPS
    ];
    allowedUDPPorts = [
      1900 # DLNA/UPnP discovery
      7359 # Jellyfin discovery
    ];
  };

  # System State Version
  system.stateVersion = "24.11"; # Don't change this
}
