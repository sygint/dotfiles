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
      
      # Note: nemo-fileroller is provided by nemo-with-extensions in system config
      
      # Additional archiving utilities for better format support
      p7zip          # 7z archives
      unrar          # RAR archives (proprietary)
      zip            # ZIP creation
      unzip          # ZIP extraction (already in system base)
      
      # Optional: Advanced archive tools  
      kdePackages.ark  # KDE's archive manager (alternative GUI, Qt6 version)
      atool           # Command-line archive tool wrapper
    ];

    # Create custom Nemo actions for archiving (more reliable than nemo-fileroller)
    home.file.".local/share/nemo/actions/compress-files.nemo_action".text = ''
      [Nemo Action]
      Name=Compress...
      Comment=Create archive with selected files
      Exec=file-roller --add %F
      Icon-Name=archive-manager
      Selection=any
      Extensions=nodirs;
      Dependencies=file-roller;
    '';

    home.file.".local/share/nemo/actions/compress-folder.nemo_action".text = ''
      [Nemo Action]
      Name=Compress Folder...
      Comment=Create archive with selected folder
      Exec=file-roller --add %F
      Icon-Name=archive-manager
      Selection=any
      Extensions=dir;
      Dependencies=file-roller;
    '';

    home.file.".local/share/nemo/actions/extract-archive.nemo_action".text = ''
      [Nemo Action]
      Name=Extract Here
      Comment=Extract archive to current directory
      Exec=file-roller --extract-here %F
      Icon-Name=archive-manager
      Selection=s
      Extensions=7z;ace;ar;arc;arj;bz;bz2;cab;cpio;deb;gz;jar;lha;lhz;lrz;lz;lzma;lzo;rar;rpm;rz;t7z;tar;tbz;tbz2;tgz;tlz;txz;tZ;tzo;war;xz;Z;zip;zoo;
      Dependencies=file-roller;
    '';

    home.file.".local/share/nemo/actions/extract-archive-to.nemo_action".text = ''
      [Nemo Action]
      Name=Extract To...
      Comment=Extract archive to chosen directory
      Exec=file-roller --extract %F
      Icon-Name=archive-manager
      Selection=s
      Extensions=7z;ace;ar;arc;arj;bz;bz2;cab;cpio;deb;gz;jar;lha;lhz;lrz;lz;lzma;lzo;rar;rpm;rz;t7z;tar;tbz;tbz2;tgz;tlz;txz;tZ;tzo;war;xz;Z;zip;zoo;
      Dependencies=file-roller;
    '';

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