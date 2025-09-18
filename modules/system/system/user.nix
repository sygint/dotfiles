{ config
, pkgs
, userVars
, ...
}:
let
  inherit (userVars) username;
in
{
  config = {
    users.users.${username} = {
      isNormalUser = true;
      description = "${username}";
      extraGroups = [ "networkmanager" "wheel" "dialout" "plugdev" ];
      shell = pkgs.zsh;
      # packages = with pkgs; [
      #   thunderbird
      # ];
    };

    environment.shells = with pkgs; [ zsh ];
  };
}
