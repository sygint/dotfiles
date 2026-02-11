# Buildbot-Nix Module - CI/CD for Nix Flakes
# Evaluates flakes and builds all outputs automatically
# Integrates with Forgejo for build status reporting
#
# This module requires buildbot-nix NixOS modules to be imported at the system
# level. Import it only on systems that have them (see flake-modules/lib.nix).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  cfg = config.modules.features.buildbot-nix;
in
{
  options.modules.features.buildbot-nix = {
    enable = mkEnableOption "Buildbot-Nix CI for Nix flake builds";

    domain = mkOption {
      type = types.str;
      default = "buildbot.home";
      description = "Domain name for the Buildbot web interface";
    };

    forgejoUrl = mkOption {
      type = types.str;
      default = "http://localhost:${toString config.modules.features.forgejo.httpPort}";
      description = "URL of the Forgejo instance to integrate with";
    };

    buildSystems = mkOption {
      type = types.listOf types.str;
      default = [ "x86_64-linux" ];
      description = "System architectures to build for";
    };

    workerCount = mkOption {
      type = types.int;
      default = 0;
      description = "Number of build workers (0 = number of CPU cores)";
    };

    evalMaxMemory = mkOption {
      type = types.int;
      default = 2048;
      description = "Max memory (MiB) per nix-eval-jobs worker";
    };

    oauthId = mkOption {
      type = types.str;
      default = "";
      description = "OAuth2 client ID from Forgejo (set after creating OAuth2 app in Forgejo)";
    };

    topic = mkOption {
      type = types.nullOr types.str;
      default = "build-with-buildbot";
      description = "Only build repos with this Forgejo topic (null = all repos)";
    };
  };

  config = mkIf cfg.enable {

    # ===== Secrets =====
    # These must be provisioned in your sops secrets
    sops.secrets = {
      "nexus/buildbot_workers" = {
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
      "nexus/buildbot_worker_password" = { };
      "nexus/buildbot_gitea_token" = {
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
      "nexus/buildbot_webhook_secret" = {
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
      "nexus/buildbot_oauth_secret" = {
        owner = "buildbot";
        group = "buildbot";
        mode = "0400";
      };
    };

    # ===== Buildbot Master (Coordinator) =====
    services.buildbot-nix.master = {
      enable = true;
      domain = cfg.domain;
      workersFile = config.sops.secrets."nexus/buildbot_workers".path;
      buildSystems = cfg.buildSystems;
      evalMaxMemorySize = cfg.evalMaxMemory;

      # Forgejo/Gitea integration
      authBackend = "gitea";
      gitea = {
        enable = true;
        instanceUrl = cfg.forgejoUrl;
        tokenFile = config.sops.secrets."nexus/buildbot_gitea_token".path;
        webhookSecretFile = config.sops.secrets."nexus/buildbot_webhook_secret".path;
        oauthId = cfg.oauthId;
        oauthSecretFile = config.sops.secrets."nexus/buildbot_oauth_secret".path;
        topic = cfg.topic;
      };
    };

    # ===== Buildbot Worker =====
    # Co-located on the same machine as master
    services.buildbot-nix.worker = {
      enable = true;
      workerPasswordFile = config.sops.secrets."nexus/buildbot_worker_password".path;
      workers = cfg.workerCount;
    };

    # Buildbot master auto-configures nginx, but we need to open the port
    # The master module sets up nginx virtualHosts automatically
    networking.firewall.allowedTCPPorts = [
      80 # Nginx (buildbot web UI reverse proxy)
    ];
  };
}
