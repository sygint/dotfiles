{ userVars, ... }:
{
  imports = [ ../base ];

  # Desktop-specific Home Manager settings
  home.file.wallpapers = {
    source = ../../../wallpapers;
    recursive = true;
  };

  settings.programs.kitty.enable = true;
}
