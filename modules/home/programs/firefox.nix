{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.firefox;
in {
  options.settings.programs.firefox = {
    enable = mkEnableOption "Firefox web browser";
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      /* ---- EXTENSIONS ---- */
      # Check about:support for extension/add-on ID strings.
      # Valid strings for installation_mode are "allowed", "blocked",
      # "force_installed" and "normal_installed".
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value= true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate"

        ExtensionSettings = with builtins;
          let extension = shortId: uuid: {
            name = uuid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
              installation_mode = "normal_installed";
            };
          };
          in listToAttrs [
            # (extension "tree-style-tab" "treestyletab@piro.sakura.ne.jp")
            (extension "ublock-origin" "uBlock0@raymondhill.net")
            (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
            # (extension "tabliss" "extension@tabliss.io")
            # (extension "umatrix" "uMatrix@raymondhill.net")
            # (extension "libredirect" "7esoorv3@alefvanoon.anonaddy.me")
            # (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
          ];
          # To add additional extensions, find it on addons.mozilla.org, find
          # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
          # Then, download the XPI by filling it in to the install_url template, unzip it,
          # run `jq .browser_specific_settings.gecko.id manifest.json` or
          # `jq .applications.gecko.id manifest.json` to get the UUID
      };
  
      /* ---- PREFERENCES ---- */
      # Check about:config for options.
      # Preferences = { 
      #   "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
      #   "extensions.pocket.enabled" = lock-false;
      #   "extensions.screenshots.disabled" = lock-true;
      #   "browser.topsites.contile.enabled" = lock-false;
      #   "browser.formfill.enable" = lock-false;
      #   "browser.search.suggest.enabled" = lock-false;
      #   "browser.search.suggest.enabled.private" = lock-false;
      #   "browser.urlbar.suggest.searches" = lock-false;
      #   "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
      #   "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
      #   "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
      #   "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
      #   "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
      #   "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
      #   "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
      #   "browser.newtabpage.activity-stream.showSponsored" = lock-false;
      #   "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
      #   "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
      # };
    };
  };
}