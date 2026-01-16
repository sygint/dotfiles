{ pkgs, opencode, ... }:
{
  # Extra user-specific packages for syg
  # This is where we add additional programs that don't need
  # their own complex configuration modules
  home.packages = with pkgs; [
    obsidian
    opencode.desktop # OpenCode Desktop app from flake
    solaar
    zed-editor
    gnome-calculator
    # Add other extra programs here as needed
  ];
}
