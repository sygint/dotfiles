{ lib, ... }:
{
  options.modules.features.niri = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Niri compositor feature configuration";
  };

  config.modules.features.niri = {
    enable = lib.mkDefault true;
    packages = {
      enable = lib.mkDefault true;
    };
  };
}
