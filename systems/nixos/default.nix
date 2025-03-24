# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, hostName, syncPassword, inputs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ../../modules/nixos.nix
  ];

  boot.loader = {
    systemd-boot.enable      = true;
    efi.canTouchEfiVariables = true;
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  settings = {
    hardware = {
      bluetooth.enable  = true;
      audio.enable      = true;
      networking = {
        enable   = true;
        hostName = "${hostName}";
      };
    };

    services = {
      # xserver.enable = true;

      protonmail-bridge.enable = true;

      syncthing = {
        enable   = true;
        username = "${username}";
        password = "${syncPassword}";
      };
    };

    system = {
      security.enable = true;

      user = {
        name = "${username}";
      };
    };

    programs = {
      nix-helpers = {
        enable = true;
        username = "${username}";
      };

      screenshots.enable = true;
    };

    wayland = {
      enable = true;

      hyprland.enable = true;
    };
  };

  # Enable the X11 windowing system.
  services = {
    xserver = {
      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable   = true;
      desktopManager.gnome.enable = true;
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # libinput.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable the systemd service for automatic login (if you want autologin)
    # displayManager.autoLogin = {
    #   enable = true;
    #   user   = "syg";
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
    image = ../../config/wallpapers/wallpaperflare.com_wallpaper-6.jpg;
    polarity = "dark";

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

  # Install firefox.
  programs = {
    firefox.enable = true;
  };

  # Allow unfree packages (e.g., proprietary software)
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    sessionVariables = {
      FLAKE = "/home/syg/.config/nixos";
    };

    systemPackages = with pkgs; [
      # services
      shiori

      # CLI applications
      curl
      fastfetch
      git
      killall
      wget
      tree
      unzip
      vim

      # Desktop applications
      brave
      firefox
      kitty
      meld
      obsidian
      signal-desktop
      inputs.zen-browser.packages."${system}".default

      # System GUI applications
      nemo
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
