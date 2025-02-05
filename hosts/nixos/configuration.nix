# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, inputs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable      = true;
    efi.canTouchEfiVariables = true;
  };

  # Basic system settings
  networking = {
    hostName              = "nixos"; # Define your hostname.
    wireless.enable     = false;  # Set to true to enable wireless support via wpa_supplicant.
    networkmanager.enable = true;

    # Configure network proxy if necessary
    # networking.proxy = {
      # default = "http://user:password@proxy:port/";
      # noProxy = "127.0.0.1,localhost,internal.domain";
    # };

    # Enable firewall (optional)
    firewall = {
      enable          = true;
      allowedTCPPorts = [ 22 80 443 ];  # Allow SSH and HTTP/HTTPS ports
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS        = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT    = "en_US.UTF-8";
      LC_MONETARY       = "en_US.UTF-8";
      LC_NAME           = "en_US.UTF-8";
      LC_NUMERIC        = "en_US.UTF-8";
      LC_PAPER          = "en_US.UTF-8";
      LC_TELEPHONE      = "en_US.UTF-8";
      LC_TIME           = "en_US.UTF-8";
    };
  };

  # Enable the X11 windowing system.
  services = {
    xserver = {
      enable = true;

      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable   = true;
      desktopManager.gnome.enable = true;

      # Configure keymap for X11 (optional)
      xkb = {
        layout  = "us"; # Set keymap layout
        variant = "";  # Use the default variant
      };
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # libinput.enable = true;

    # Enable CUPS to print documents.
    printing.enable = true;

    # Disable PulseAudio (will use PipeWire)
    pulseaudio.enable = false;

    # Configure audio
    pipewire = {
      enable                 = true; # Enable PipeWire for audio
      alsa.enable            = true; # Enable ALSA support for PipeWire
      # alsa.support32Bit    = true;
      pulse.enable           = true; # Enable PulseAudio emulation for PipeWire
      # If you want to use JACK applications, uncomment this
      #jack.enable           = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      # media-session.enable = true;
    };

    # Configure SSH server (optional)
    openssh.enable = true;

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      settings.gui = {
        user = "${username}";
        password = "syncmybattleship";
      };
    };

    # Enable the systemd service for automatic login (if you want autologin)
    # displayManager.autoLogin = {
    #   enable = true;
    #   user   = "syg";
    # };
    
    protonmail-bridge.enable = true;
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  # systemd.services = {
  #   "getty@tty1".enable  = false;
  #   "autovt@tty1".enable = false;
  # };

  # User configuration (set up user account)
  users.users.syg = {
    isNormalUser  = true;
    description   = "syg";
    extraGroups   = [ "networkmanager" "wheel" ];
    # shell       = pkgs.zsh;
    packages      = with pkgs; [
    #  thunderbird
    ];
  };

  # Set up sudo for the 'wheel' group
  security = {
    sudo = {
      enable             = true;
      wheelNeedsPassword = true;
    };

    rtkit.enable = true;
  };

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

    hyprland = {
      enable  = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    };
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
      # Nix utilities
      nh
      nix-output-monitor
      nvd

      # services
      protonmail-bridge
      shiori

      # Screenshot utilities
      grim
      slurp
      swappy

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

      # System GUI applications
      hyprpanel
      hyprlock
      hypridle
      nemo
      wdisplays
      rofi-wayland
      swww
      waypaper
      xdg-desktop-portal-hyprland
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
