{
  config,
  username,
  pkgs,
  ...
}: {
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