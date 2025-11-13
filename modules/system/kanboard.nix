{ config, pkgs, ... }:

{
  # Kanboard - Simple Kanban board, one service, that's it
  services.kanboard = {
    enable = true;
    domain = "localhost";
  };

  # That's literally it. Just visit http://localhost:9000
  # Default login: admin / admin
}