{
  # NixOS system configuration variables
  
  hostName = "orion";
  username = "syg";

  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "sygint";
  gitEmail    = "sygint@users.noreply.github.com";

  # Hyprland Application Configuration
  terminal     = "ghostty";
  fileManager  = "nemo";
  webBrowser   = "librewolf";
  menu         = "wofi";

  # Password for Syncthing
  syncPassword = "syncmybattleship";
}
