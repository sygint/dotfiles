{ pkgs, ... }:
{
  # Extra user-specific packages for syg
  # This is where we add additional programs that don't need
  # their own complex configuration modules
  home.packages = with pkgs; [
    obsidian
    opencode
    solaar
    # Add other extra programs here as needed
  ];
}
