{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.archiver;
in
{
  options.modules.programs.archiver = {
    enable = mkEnableOption "Enable archive management with Nemo integration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Core archive manager (GNOME's archive tool)
      file-roller
      
      # Nemo integration for right-click archive operations
      nemo-fileroller
      
      # Additional archiving utilities for better format support
      p7zip          # 7z archives
      unrar          # RAR archives (proprietary)
      zip            # ZIP creation
      unzip          # ZIP extraction (already in system base)
      
      # Optional: Advanced archive tools
      ark            # KDE's archive manager (alternative GUI)
      atool          # Command-line archive tool wrapper
    ];

    # Configure file associations for archive formats
    xdg.mimeApps.defaultApplications = {
      # Archive formats -> File Roller
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-bzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-xz-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
    };
  };
}