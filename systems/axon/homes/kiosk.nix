# Minimal Home Manager configuration for Axon kiosk user
{ config, pkgs, ... }:

{
  # Basic user info
  home.username = "kiosk";
  home.homeDirectory = "/home/kiosk";

  # Home Manager release version
  home.stateVersion = "24.11";

  # Minimal packages for kiosk mode
  home.packages = with pkgs; [
    # Only essential media packages
    jellyfin-media-player
  ];

  # Minimal shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      # Emergency commands for troubleshooting
  admin = "sudo -u axon -i";  # Switch to axon user
      restart-jellyfin = "systemctl --user restart jellyfin-kiosk";
    };
  };

  # Kiosk-optimized desktop configuration
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      enable-animations = false;
    };
    
    # Hide desktop elements for kiosk mode
    "org/gnome/desktop/background" = {
      show-desktop-icons = false;
    };
    
    # Disable screen lock for media playback
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      idle-activation-enabled = false;
    };
    
    # Power settings optimized for continuous playback
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";  # Allow battery sleep
      idle-dim = false;
    };
    
    # Disable unnecessary GNOME features
    "org/gnome/desktop/privacy" = {
      disable-microphone = true;
      disable-camera = true;
    };
    
    # Emergency keyboard shortcuts
    "org/gnome/desktop/wm/keybindings" = {
      # Ctrl+Alt+T opens terminal for emergency access
      # Ctrl+Alt+Esc kills current application
      close = [ "<Alt>F4" ];
    };
  };

  # XDG configuration for media directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = false;  # Don't create unnecessary directories
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}