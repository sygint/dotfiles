{ config, pkgs, username, host, inputs, ... }:
let
  inherit (import ./variables.nix) gitUsername gitEmail;
in
{
  # Home Manager Settings
  home.username      = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "24.11";

  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  home = {
    file = {
      ".gitconfig".source      = ../../config/.gitconfig;
      "hypr/mocha.conf".source = ../../config/hypr/mocha.conf.nix;
      wallpapers = {
        source = ../../config/wallpapers;
        recursive = true;
      };
    };

    packages = [
      (import ../../scripts/screenshootin.nix { inherit pkgs; })
    ];
  };

  wayland.windowManager = {
    hyprland = {
      enable      = true;
      # plugins   = [];
      extraConfig = (import ../../config/hypr/hyprland.conf.nix);
    };

    sway.enable = true;
  };

  # Install & Configure Git
  programs = {
    home-manager.enable = true;
    rofi.enable         = true;

    btop = {
      enable            = true;
      settings.vim_keys = true;
    };

    kitty = {
      enable      = true;
      package     = pkgs.kitty;
      extraConfig = (import ../../config/kitty/kitty.nix);
    };

    hyprlock = {
      enable      = true;
      extraConfig = (import ../../config/hypr/hyprlock.conf.nix { inherit username; });
    };

    chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        # "ldpochfccmkkmhdbclfhpagapcfdljkj" # Decentraleyes
        "ikclbgejgcbdlhjmckecmdljlpbhmbmf" # HTTPS Everywhere
        # "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
        # "fploionmjgeclbkemipmkogoaohcdbig" # Page Load time
        "hmgpakheknboplhmlicfkkgjipfabmhp" # Privacy | Private Debit Cards
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger        
        "fmkadmapgofadopljbjfkapdkoienihi" # React Developer Tools
        # "hjdoplcnndgiblooccencgcggcoihigg" # Terms of Service; Didn’t Read
      ];
    };

    firefox = {
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

    vscode = {
      enable = true;
      profiles.default = {
        userSettings = {
          "editor.minimap.enabled" = false;
          "svelte.enable-ts-plugin" = true;
          "diffEditor.renderSideBySide" = false;
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.tabSize" =  2;
          "editor.indentSize" = "tabSize";
        };
        extensions = with pkgs.vscode-extensions; [
          # themes
          dracula-theme.theme-dracula

          # syntax
          jnoortheen.nix-ide
          bbenoist.nix
          # vscodevim.vim
          yzhang.markdown-all-in-one

        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "gitless";
            publisher = "maattdd";
            version = "11.7.2";
            sha256 = "rYeZNBz6HeZ059ksChGsXbuOao9H5m5lHGXJ4ELs6xc=";
          }
          {
            name = "vscode-kanbn-boards";
            publisher = "samgiz";
            version = "0.14.1";
            sha256 = "+BIMS5icyEmj1JXKVZmcOfTFI4w/F1zpjbt9ziG7XEk=";
          }
          {
            name = "svelte-vscode";
            publisher = "svelte";
            version = "109.5.2";
            sha256 = "y1se0+LY1M+YKCm+gxBsyHLOQU6Xl095xP6z0xpf9mM=";
          }
          {
            name = "vscode-tailwindcss";
            publisher = "bradlc";
            version = "0.14.1";
            sha256 = "eOdltfRP4npYfQKDhGgP2gtc7jrqOv6igWP6DLfJGRw=";
          }
          {
            name = "vscode-versionlens";
            publisher = "pflannery";
            version = "1.16.2";
            sha256 = "avrq1e+L+2ZCIDBz1WOOHtU9a16VNkDOzrE1ccPnTKg=";
          }
        ];
      };
    };
  };

  services = {
    hypridle = {
      enable   = true;
      settings = {
        general = {
          lock_cmd            = "pidof hyprlock || hyprlock";  # avoid starting multiple hyprlock instances.
          before_sleep_cmd    = "loginctl lock-session";       # lock before suspend.
          after_sleep_cmd     = "hyprctl dispatch dpms on";    # to avoid having to press a key twice to turn on the display.
          ignore_dbus_inhibit = false;
        };

        listener = [
          # Screenlock
          {
            timeout    = 300;
            on-timeout = "hyprlock";
          }
          # DPMS
          {
            timeout    = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }
          # Suspend
          # {
          #   timeout    = 1200;
          #   on-timeout = "systemctl suspend";
          # }
        ];
      };
    };

    # This doesn't seem to work for some reason
    # xdg-desktop-portal-hyprland.enable = true;
  };

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable            = true;
      createDirectories = true;
    };

    # configFile."Code/User/settings.json".source =
    #   config.lib.file.mkOutOfStoreSymlink
    #   "${config.home.homeDirectory}/.config/nixos/dotfiles/vscode/settings.json";
  };
}
