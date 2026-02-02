{ lib, ... }:
{
  options.modules.features.noctalia-shell = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Noctalia Shell - Minimal Quickshell-based desktop shell for Wayland";
  };

  config.modules.features.noctalia-shell = {
    enable = lib.mkDefault false;
  };
}
