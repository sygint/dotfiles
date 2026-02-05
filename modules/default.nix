{ inputs, ... }:
{
  # Master module import - imports all modules from the modules/ directory
  #
  # This consolidates:
  # - features/ → Feature modules (hyprland, vscode, etc.)
  # - system/   → System-level configuration (base settings, ai-services, etc.)
  # - home/     → Home Manager base configuration
  #
  # Each system config can now simply import ../../modules instead of
  # importing features, system, and home separately.

  imports = [
    ./features # All feature modules
    ./system # System base + ai-services, etc.
    ./home.nix # Home Manager modules
  ];
}
