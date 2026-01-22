{ pkgs, ... }:
{
  home.packages = [
    (import ../../../../Projects/open-source/focalboard-cli {}).focalboard-cli
  ];
}
