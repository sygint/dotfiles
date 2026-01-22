# Auto-sync user passwords from SOPS secrets files
# This module ensures passwords are updated on every activation, not just user creation
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.secrets-password-sync;
in
{
  options.modules.system.secrets-password-sync = {
    enable = mkEnableOption "automatic password synchronization from SOPS secrets";

    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          passwordSecretPath = mkOption {
            type = types.str;
            description = "Path to the SOPS secret containing the password hash";
            example = "config.sops.secrets.\"hostname/username_password_hash\".path";
          };
        };
      });
      default = {};
      description = "Users whose passwords should be auto-synced from secrets";
      example = literalExpression ''
        {
          rescue = {
            passwordSecretPath = config.sops.secrets."nexus/rescue_password_hash".path;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.syncPasswordsFromSecrets = stringAfter [ "users" ] ''
      ${concatStringsSep "\n" (mapAttrsToList (username: userCfg: ''
        if [ -f "${userCfg.passwordSecretPath}" ]; then
          NEW_HASH=$(cat "${userCfg.passwordSecretPath}")
          echo "${username}:$NEW_HASH" | ${pkgs.shadow}/bin/chpasswd --encrypted
        fi
      '') cfg.users)}
    '';
  };
}
