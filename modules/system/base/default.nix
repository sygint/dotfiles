{ config, pkgs, lib, ... }:
{
  # Base NixOS configuration - essential settings for any system
  
  # Essential boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Base system settings
  modules = {
    system.security.enable = true;
    programs.nix-helpers.enable = true;
  };

  # Essential system programs
  programs = {
    zsh.enable = true;
    nix-index.enable = true;
    command-not-found.enable = false;
    dconf.enable = true;  # Required for many desktop services
  };

  # Essential system services
  services = {
    dbus.enable = true;
    udisks2.enable = true;  # Disk mounting
    upower.enable = true;   # Power management
  };

  # Core system packages - essential for any NixOS system
  environment.systemPackages = with pkgs; [
    # Essential shell tools
    zsh
    
    # Essential CLI applications
    curl
    file
    gnupg
    jq
    killall
    libnotify
    lsof
    nh
    nix-index
    wget
    unzip
    vim

    # Essential development tools
    git
    just  # Task automation for NixOS config management
    deploy-rs  # Remote NixOS deployment tool

    # Essential system tools
    home-manager
  ];

  # Allow unfree packages (needed for NVIDIA drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Essential Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Allow all wheel group users to push unsigned paths to nix store
    # This enables passwordless deploy-rs deployments via SSH authentication
    trusted-users = [ "root" "@wheel" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
