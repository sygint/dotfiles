{ userVars, ... }:
{
  imports = [ ../_base ];

  # Desktop-specific Home Manager settings
  home.file.wallpapers = {
    source = ../../../wallpapers;
    recursive = true;
  };

  modules.programs.kitty.enable = true;
}
