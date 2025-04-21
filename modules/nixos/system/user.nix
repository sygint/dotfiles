{
  config,
  userVars,
  pkgs,
  ...
}:
  let
    inherit (userVars) username;
  in
{
  config = {
    users.users.${username} = {
      isNormalUser = true;
      description  = "${username}";
      extraGroups  = [ "networkmanager" "wheel" ];
      shell        = pkgs.zsh;
    };

    environment.shells = with pkgs; [ zsh ];
  };
}