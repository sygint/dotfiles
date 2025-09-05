{ userVars, ... }:
{
  # Desktop-specific Home Manager settings
  home.file.wallpapers = {
    source = ../../../wallpapers;
    recursive = true;
  };

  settings.programs.kitty.enable = true;

  # Add more desktop-specific programs/configs here
}
