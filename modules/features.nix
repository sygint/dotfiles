{ inputs, ... }:
{
  # Auto-import all unified feature modules via import-tree
  # Feature modules combine both system and home-manager configuration
  imports = [
    (inputs.import-tree ./features)
  ];
}
