{ userVars, ... }:
{
  imports = [ ../_base ];

  # Desktop-specific Home Manager settings
  home.file.wallpapers = {
    source = ../../../wallpapers;
    recursive = true;
  };

  # kitty now managed by unified features.kitty module in system config
}
