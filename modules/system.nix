{ inputs, ... }:
{
  # Auto-import all system modules via import-tree (Phase 1: dendritic-lite)
  # All modules are imported, but only enabled modules are activated per system.
  # See: https://github.com/vic/import-tree
  imports = [
    (inputs.import-tree ./system)
  ];

  # NOTE: ai-services module is imported here but only enabled by systems/cortex/default.nix
  # It's Cortex-specific (NVIDIA GPU, Ollama, etc.) but following dendritic pattern of
  # importing everywhere and enabling selectively.
}
