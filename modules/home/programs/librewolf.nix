{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.librewolf;
in
{
  options.settings.programs.librewolf.enable = mkEnableOption "Librewolf web browser";

  config = mkIf cfg.enable {
    programs.librewolf = {
      enable = true;

      /* ---- EXTENSIONS ---- */
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        # DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "newtab"; # alternatives: "always" or "newtab"
        DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate"

        Preferences = {
          # Check about:config for options.
          "cookiebanners.service.mode" = 2; # Block cookie banners
          "cookiebanners.service.mode.privateBrowsing" = 2; # Block cookie banners in private browsing

          # privacy
          "privacy.clearOnShutdown.cookies" = true;
          "privacy.donottrackheader.enabled" = true;
          #  --- protections enabled by default ---
          # "privacy.clearOnShutdown.history" = false;
          # "privacy.fingerprintingProtection" = true;
          # "privacy.resistFingerprinting" = true;
          # "privacy.trackingprotection.emailtracking.enabled" = true;
          # "privacy.trackingprotection.enabled" = true;
          # "privacy.trackingprotection.fingerprinting.enabled" = true;
          # "privacy.trackingprotection.socialtracking.enabled" = true;
          # "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
          # "webgl.disabled" = true;

          # other
          "sidebar.revamp" = true; # Enable the revamped sidebar, needed for verticalTabs
          "sidebar.verticalTabs.enabled" = false; # Disable vertical tabs sidebar
          "extensions.screenshots.disabled" = true;
          "browser.topsites.contile.enabled" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
          #  --- protections enabled by default ---
          # "extensions.pocket.enabled" = false;
          # "browser.formfill.enable" = false;
          # "browser.search.suggest.enabled" = false;
          # "browser.search.suggest.enabled.private" = false;
          # "browser.urlbar.suggest.searches" = false;
          # "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          # "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
          # "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          # "browser.newtabpage.activity-stream.showSponsored" = false;
          # "browser.newtabpage.activity-stream.system.showSponsored" = false;
          # "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        };

        ExtensionSettings = with builtins;
          let
            extension = shortId: uuid: {
              name = uuid;
              value = {
                install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
                installation_mode = "normal_installed";
              };
            };
          in
          listToAttrs [
            (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
            (extension "proton-vpn-firefox-extension" "vpn@proton.ch")
            (extension "multi-account-containers" "@testpilot-containers") # Firefox Multi-Account Containers
            (extension "pay-by-privacy" "privacy@privacy.com")
            (extension "keepassxc-browser" "keepassxc-browser@keepassxc.org")
            (extension "ublock-origin" "keepassxc-browser@keepassxc.org")
            # Additional popular extensions (uncomment to enable):
            # (extension "tree-style-tab" "treestyletab@piro.sakura.ne.jp")
            # (extension "tabliss" "extension@tabliss.io")
            # (extension "umatrix" "uMatrix@raymondhill.net")
            # (extension "libredirect" "7esoorv3@alefvanoon.anonaddy.me")
            # (extension "darkreader" "addon@darkreader.org")               # Dark Reader
            # (extension "violentmonkey" "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}") # Violentmonkey
          ];
      };
    };
  };
}
