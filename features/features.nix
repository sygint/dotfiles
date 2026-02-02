{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./)
  ];
}
