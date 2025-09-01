# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, fh, userVars, lib, ... }:
  let
    systemVars = import ./variables.nix;
    inherit (systemVars.system) hostName username syncPassword;
  in
{
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ../../modules/nixos.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable      = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "ntfs" ];
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

      mullvad.enable = true;


      syncthing = {
        enable   = true;
        username = "${username}";
        password = "${syncPassword}";
      };

      virtualization = {
        enable = true;
        service = "virtualbox";
        username = "${username}";
      };

      containerization = {
        enable = true;
        service = "podman";
      };
    };

    system = {
      security.enable = true;
    };

    programs = {
      nix-helpers.enable = true;
    };

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

    # Enable CUPS to print documents.
    printing.enable = true;

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
    platformTheme = "qt5ct";  # Use qt5ct to match stylix configuration
    # Let stylix handle the style
  };

  programs = {
    zsh.enable = true;
    nix-index.enable = true;
    command-not-found.enable = false;
  };
  # nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    sessionVariables = {
      NH_FLAKE = "/home/${username}/.config/nixos";
    };

    systemPackages = with pkgs; [
      # shell
      antidote
      starship
      zsh

      # CLI applications
      bat
      curl
      eza
      fastfetch
      fd
      fzf
      gnupg
      jq
      killall
      libnotify # for notify-send
      lsof
      nix-index
      wget
      tealdeer
      tree
      unzip
      vim
      yazi
      zellij
      zoxide

      # Desktop applications
      brave
      element-desktop
      ghostty
      gimp
      gparted
      keepassxc
      kitty
      librewolf-unwrapped
      meld
      nemo
      shiori
      signal-desktop
      inputs.zen-browser.packages."${system}".default

      # Software Development
      act # gh actions cli
      direnv
      git
      lazygit

      # other
      home-manager
      fh.packages.x86_64-linux.default
      
      # Qt theming support
      libsForQt5.qt5ct
      qt6ct
      adwaita-qt
      adwaita-qt6
    ];
  };

  # Allow unfree packages (e.g., proprietary software)
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "obsidian"
    "slack"
    "synology-drive-client"
    "vscode"
    "Oracle_VirtualBox_Extension_Pack"
    "vscode-extension-mhutchie-git-graph"
  ];

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
