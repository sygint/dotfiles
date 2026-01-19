# Home Manager configuration for Axon admin user
{
  config,
  pkgs,
  inputs,
  userVars,
  ...
}:

{
  # Basic user info
  home.username = userVars.username;
  home.homeDirectory = "/home/${userVars.username}";

  # Home Manager release version
  home.stateVersion = "24.11";

  # Admin/media center user packages
  home.packages = with pkgs; [
    jellyfin-media-player
    kodi
    vlc
    mpv
    firefox
    mediainfo
    ffmpeg
    yt-dlp
    remmina
    nemo-with-extensions
    alacritty
    starship
    zoxide
    fzf
    eza
    bat
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = userVars.name;
        email = userVars.email;
      };
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "eza -l";
      la = "eza -la";
      tree = "eza --tree";
      cat = "bat";
      cd = "z";
    };
    initContent = ''
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      directory = {
        style = "bold cyan";
        truncation_length = 3;
      };
    };
  };

  programs.firefox = {
    enable = true;
    profiles.default = {
      name = "Axon";
      settings = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "gfx.webrender.all" = true;
        "full-screen-api.enabled" = true;
        "browser.fullscreen.autohide" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
      };
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      enable-animations = false;
    };
    "org/gnome/shell" = {
      favorite-apps = [
        "jellyfin-media-player.desktop"
        "kodi.desktop"
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      videos = "${config.home.homeDirectory}/Videos";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      download = "${config.home.homeDirectory}/Downloads";
    };
  };

  services = {
    ssh-agent.enable = true;
  };

  programs.home-manager.enable = true;
}
