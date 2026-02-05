{ inputs, ... }:
{
  # Master module import - imports all modules from the modules/ directory
  #
  # This consolidates:
  # - features/ → Feature modules (hyprland, vscode, etc.)
  # - system/   → System-level configuration (base settings, ai-services, etc.)
  # - home/     → Home Manager base configuration (imported via home-manager.sharedModules)
  #
  # Each system config can now simply import ../../modules instead of
  # importing features, system, and home separately.

  imports = [
    ./features # All feature modules
    ./system # System base + ai-services, etc.
  ];

  # Home Manager modules are imported via home-manager.sharedModules in system configs
  # This is because home modules need userVars which isn't available at this level
}
