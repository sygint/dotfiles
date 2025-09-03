{
  config,
  userVars,
  pkgs,
  ...
}:
  let
    inherit (userVars.user) username;
  in
{
  config = {
    users.users.${username} = {
      isNormalUser = true;
      description  = "${username}";
      extraGroups  = [ "networkmanager" "wheel" "dialout" ];
      shell        = pkgs.zsh;
      # packages = with pkgs; [
      #   thunderbird
      # ];
    };

    environment.shells = with pkgs; [ zsh ];
  };
}