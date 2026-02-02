# Moves the real import logic so it's never recursively imported.
{ inputs, ... }: {
  imports = [ (inputs.import-tree ./) ];
}
