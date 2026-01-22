# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

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
      userVars = systemVars.user // {
        inherit hostName;
      };
      opencode = inputs.opencode.packages.${pkgs.system};
    };
    # Auto back up files that would be clobbered by Home Manager so that
    # unmanaged files are not lost during activation. This prevents
    # activations from failing due to existing files like
    # '/home/syg/.mozilla/firefox/profiles.ini'. The extension can be
    # changed as needed.
    backupFileExtension = ".hm-backup";
    # Disable stylix librewolf target to suppress warning
    sharedModules = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      {
        stylix.targets.librewolf.enable = false;
      }
    ];
    users.syg = import ./homes/syg.nix;
  };

  boot = {
    supportedFilesystems = [ "ntfs" ];
  };

  # Set timezone from global fleet config
  time.timeZone = fleetConfig.global.timeZone;

  # Enable Logitech device support
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # Enable hardware video acceleration for AMD graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # AMD video acceleration
      mesa
      libva
      libva-utils
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # Additional udev rules for Logitech devices with plugdev group access
  services.udev.extraRules = ''
    # Enable plugdev group access for Logitech devices
    KERNEL=="uinput", SUBSYSTEM=="misc", GROUP="input", MODE="0664"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", GROUP="plugdev", MODE="0664"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", GROUP="plugdev", MODE="0664"
  '';

  # User is now defined directly below
  users.users.syg = {
    isNormalUser = true;
    description = "syg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "plugdev"
    ];
    shell = pkgs.zsh;
  };
  environment.shells = with pkgs; [ zsh ];

  # Add cortex to local hosts for DNS resolution (temporary until UDM DNS fixed)
  networking.extraHosts = ''
    192.168.1.7 cortex.home cortex
  '';

  modules = {
    hardware = {
      bluetooth.enable = true;
      audio.enable = true;
      networking = {
        enable = true;
        hostName = "${hostName}";
      };
    };

    features = {
      zsh.enable = true;
      mullvad.enable = true; # Unified system + home config
      hyprland = {
        enable = true;
        packages.enable = true;
      };
      # Hyprland ecosystem
      hyprpanel.enable = true;
      hypridle.enable = true;
      waybar.enable = false; # Disabled in favor of hyprpanel
      screenshots.enable = true;
      # Development tools
      git.enable = true;
      kitty.enable = true;
      btop.enable = true;
      devenv.enable = true;
      vscode = {
        enable = true;
        variant = "fhs"; # FHS environment for imperative extension management
        copilotPrompts.enable = true;
      };
      # Web browsers
      brave.enable = true;
      firefox.enable = true;
      librewolf.enable = true;
    };

    services = {
      # xserver.enable = true;

      syncthing = {
        enable = true;
        username = "${username}";
        # Password now managed by sops-nix secrets
      };

      virtualization = {
        enable = true;
        service = "qemu"; # Temporarily using QEMU (VirtualBox build failing)
        username = "${username}";
      };

      containerization = {
        enable = true;
        service = "podman";
      };

      printing = {
        enable = true;
        enableAutoDiscovery = true;
        enableSharing = false;
      };
    };

    # Enable security module with sudo password requirement
    system.security = {
      enable = true; # Enable sudo with wheelNeedsPassword
    };

    # Base security and program modules are enabled in base config

    # Wayland-specific settings (Hyprland now in features.hyprland)
    wayland.enable = true;
  };

  # ════════════════════════════════════════════════════════════════════════════
  # NO DISPLAY MANAGER - TTY LOGIN
  # ════════════════════════════════════════════════════════════════════════════
  # Using direct TTY login to avoid PAM/session issues with display managers.
  # Login at TTY, then Hyprland starts automatically via .zlogin.

  # Set keyboard layout for TTY console
  console.keyMap = "us";

  fonts.packages = with pkgs; [
    pkgs.nerd-fonts.fira-code
    pkgs.nerd-fonts.droid-sans-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    image = ../../wallpapers/wallpaperflare.com_wallpaper-6.jpg;
    polarity = "dark";

    # Fix Qt platform warning
    targets.qt.platform = pkgs.lib.mkForce "qtct";

    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

  # Fix deprecated Qt platform theme warning
  qt = {
    enable = true;
    platformTheme = "qt5ct"; # Use qt5ct to match stylix configuration
    # Let stylix handle the style
  };

  # Base system programs (zsh, nix-index, etc.) are enabled in base config

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    sessionVariables = {
      NH_FLAKE = "/home/${username}/.config/nixos";
    };

    systemPackages = with pkgs; [
      # Enhanced CLI applications (base has basic set)
      # Note: bat, eza, fd, fzf, zoxide provided by features.zsh module
      fastfetch
      tealdeer
      tree
      usbutils
      yazi
      zellij

      # Desktop applications
      element-desktop
      ghostty
      gimp
      gparted
      keepassxc
      kitty
      libreoffice
      librewolf-unwrapped
      meld
      nemo-with-extensions # Nemo with file-roller and other extensions
      rocketchat-desktop
      shiori
      signal-desktop
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Enhanced development tools (base has basic git)
      act # gh actions cli
      gh # GitHub CLI for PR and repo management
      direnv
      lazygit

      # System-specific tools
      fh.packages.x86_64-linux.default

      # Qt theming support
      libsForQt5.qt5ct
      qt6Packages.qt6ct
      adwaita-qt
      adwaita-qt6
    ];
  };

  # Extend base unfree packages with orion-specific ones
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "obsidian"
      "slack"
      "synology-drive-client"
      "vscode"
      "vscode-with-extensions"
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
      "Oracle_VirtualBox_Extension_Pack"
      "vscode-extension-mhutchie-git-graph"
    ];

  nix.settings.trusted-users = [
    "root"
    "syg"
  ];

  # WiFi undock fix - passwordless sudo for driver reload
  security.sudo.extraRules = [
    {
      users = [ "syg" ];
      commands = [
        {
          command = "${pkgs.kmod}/bin/modprobe";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.iproute2}/bin/ip";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Base Nix settings, like flakes, are handled in base config

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable           = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # System State Version Handled in base config
}
