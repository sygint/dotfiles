{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    devenv
    cachix # Remove this line if you want cachix to remain system-level only
  ];
}
