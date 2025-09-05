{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.system.security;
in
{
  options.settings.system.security.enable = mkEnableOption "Security";

  config = mkIf cfg.enable {
    security = {
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
      };

      rtkit.enable = true;
      polkit.enable = true;
    };

    # Enable gnome-keyring for secure storage (works in all desktop environments)
    services.gnome.gnome-keyring.enable = true;

    # PAM configuration for gnome-keyring automatic unlock
    security.pam.services = {
      login.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
      greetd.enableGnomeKeyring = true;
    };

    # Install secret management tools
    environment.systemPackages = with pkgs; [
      libsecret # For secret-tool command-line access
    ];
  };
}
