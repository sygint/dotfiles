# This file is used for system-wide configuration of NixOS.

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Basic system settings
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap for X11 (optional)
  services.xserver.xkb = {
    layout = "us";  # Set keymap layout
    variant = "";    # Use the default variant
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Configure audio
  hardware.pulseaudio.enable = false;  # Disable PulseAudio (will use PipeWire)
  services.pipewire.enable = true;     # Enable PipeWire for audio
  services.pipewire.alsa.enable = true;  # Enable ALSA support for PipeWire
  services.pipewire.pulse.enable = true;  # Enable PulseAudio emulation for PipeWire

  # User configuration (set up user account)
  users.users.syg = {
    isNormalUser = true;
    description = "syg";
    extraGroups = [ "wheel" ];  # Add user to 'wheel' group for sudo access
    # shell = pkgs.zsh;           # Use zsh as the shell
  };

  # Set up sudo for the 'wheel' group
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;

  # Enable firewall (optional)
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];  # Allow SSH and HTTP/HTTPS ports

  # Configure SSH server (optional)
  services.openssh.enable = true;

  # Enable the systemd service for automatic login (if you want autologin)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "syg";

  # Install system-wide packages
  environment.systemPackages = with pkgs; [
    curl      # Command-line tool for transferring data
    firefox   # Web browser
    git
    wget      # Download utility
    vim       # Text editor for configuration editing
  ];

  # Allow unfree packages (e.g., proprietary software)
  nixpkgs.config.allowUnfree = true;

  # Set NixOS system state version (should match the version you're using)
  system.stateVersion = "24.05";  # Update this to match the NixOS release version you're using

  # Enable some other useful services (uncomment to enable)
  # services.openssh.enable = true;  # Enable OpenSSH server
  # services.xserver.libinput.enable = true;  # Enable touchpad support
}
