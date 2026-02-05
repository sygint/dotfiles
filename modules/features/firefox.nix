{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.firefox;
in
{
  options.modules.features.firefox.enable =
    mkEnableOption "Firefox web browser (standard, for work/media with full device access)";

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} = {
      # Tell stylix which Firefox profiles to style
      stylix.targets.firefox.profileNames = [ "default" ];

      programs.firefox = {
        enable = true;

        profiles.default = {
          name = "Default";
          isDefault = true;

          settings = {
            # Hardware acceleration
            "media.ffmpeg.vaapi.enabled" = true;
            "media.hardware-video-decoding.force-enabled" = true;
            "gfx.webrender.all" = true;
            "layers.acceleration.force-enabled" = true;

            # Media device access - full enumeration for video conferencing
            # This is the key difference from LibreWolf - allows proper device detection
            "media.navigator.streams.fake" = false; # Use real devices, not fake ones
            "media.getusermedia.insecure.enabled" = true; # Allow on HTTP (for local dev)
            "permissions.default.microphone" = 0; # 0=always ask
            "permissions.default.camera" = 0; # 0=always ask

            # Basic privacy (lighter than LibreWolf)
            "privacy.trackingprotection.enabled" = true;
            "privacy.donottrackheader.enabled" = true;
            "browser.contentblocking.category" = "standard"; # Not strict, for compatibility

            # Disable telemetry
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.archive.enabled" = false;

            # UI preferences
            "browser.toolbars.bookmarks.visibility" = "newtab";
            "browser.startup.page" = 3; # Restore previous session
            "browser.tabs.loadInBackground" = true;
            "full-screen-api.enabled" = true;
            "browser.fullscreen.autohide" = true;

            # Cookie management (keep logged in to work sites)
            "privacy.clearOnShutdown.cookies" = false; # Keep cookies for convenience
            "privacy.clearOnShutdown.history" = false; # Keep history

            # WebRTC (needed for video conferencing)
            "media.peerconnection.enabled" = true;
            "media.peerconnection.ice.default_address_only" = false; # Allow all ICE candidates
            "media.peerconnection.ice.no_host" = false; # Show local IP for WebRTC
            "media.peerconnection.ice.proxy_only_if_behind_proxy" = false;
            "media.peerconnection.turn.disable" = false; # Allow TURN servers
            "media.peerconnection.use_document_iceservers" = true; # Use site's ICE servers

            # Additional WebRTC settings for better connectivity
            "media.navigator.permission.disabled" = false; # Require permission prompts
            "media.autoplay.default" = 0; # Allow autoplay (needed for calls)
            "media.autoplay.blocking_policy" = 0; # Don't block autoplay
          };
        };
      };
    };
  };
}
