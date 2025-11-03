# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, fh, lib, hasSecrets, ... }:
let
  systemVars = import ./variables.nix;
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
  ] ++ lib.optionals hasSecrets [
    (import (inputs.nixos-secrets + "/default.nix") { inherit config lib pkgs inputs hasSecrets; })
  ];

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      userVars = systemVars.user;
    };
    users.syg = import ./homes/syg.nix;
  };

  boot = {
    supportedFilesystems = [ "ntfs" ];
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

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
      vaapiVdpau
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
    extraGroups = [ "networkmanager" "wheel" "dialout" "plugdev" ];
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

    services = {
      # xserver.enable = true;

      mullvad.enable = true;

      syncthing = {
        enable = true;
        username = "${username}";
        # Password now managed by sops-nix secrets
      };

      virtualization = {
        enable = true;
        service = "qemu";  # Temporarily using QEMU (VirtualBox build failing)
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

    # Base security and program modules are enabled in base config

    wayland = {
      enable = true;

      hyprland.enable = true;
    };
  };

  # Enable the X11 windowing system.
  services = {
    # snap.enable = true;

    # Fixed deprecated options
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).
    # libinput.enable = true;

    # Enable the systemd service for automatic login (if you want autologin)
    # displayManager.autoLogin = {
    #   enable = true;
    #   user   = "${username}";
    # };
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  # systemd.services = {
  #   "getty@tty1".enable  = false;
  #   "autovt@tty1".enable = false;
  # };

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
        package = pkgs.noto-fonts-emoji;
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
      # Enhanced shell tools (base has basic zsh)
      antidote
      starship

      # Enhanced CLI applications (base has basic set)
      bat
      eza
      fastfetch
      fd
      fzf
      tealdeer
      tree
      usbutils
      yazi
      zellij
      zoxide

      # Desktop applications
      element-desktop
      ghostty
      gimp
      gparted
      keepassxc
      kitty
      librewolf-unwrapped
      meld
      nemo-with-extensions  # Nemo with file-roller and other extensions
      shiori
      signal-desktop
      inputs.zen-browser.packages."${system}".default

      # Enhanced development tools (base has basic git)
      act # gh actions cli
      direnv
      lazygit

      # System-specific tools
      fh.packages.x86_64-linux.default

      # Qt theming support
      libsForQt5.qt5ct
      qt6ct
      adwaita-qt
      adwaita-qt6
    ];
  };

  # Extend base unfree packages with orion-specific ones
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
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

  nix.settings.trusted-users = [ "root" "syg" ];

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
