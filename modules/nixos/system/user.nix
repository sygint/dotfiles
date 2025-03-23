{
  config,
  lib,
  options,
  pkgs,
  username,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.system.user;
in {
  options.settings.system.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Username for the creating account";
    };
  };

  config = {
    users.users.${cfg.name} = {
      isNormalUser  = true;
      description   = "${cfg.name}";
      extraGroups   = [ "networkmanager" "wheel" ];
      # shell       = pkgs.zsh;
      packages      = with pkgs; [
      #  thunderbird
      ];
    };
  };
}