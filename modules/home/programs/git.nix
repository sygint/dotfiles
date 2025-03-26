{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.git;
in {
  options.settings.programs.git = {
    enable = mkEnableOption "Git";

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Username for the git";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email for the git";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      # lfs.enable = true;

      userName = "${cfg.userName}";
      userEmail = "${cfg.userEmail}";

      aliases = {
        # general
        s  = "status";
        l  = "log";
        b  = "branch";
        aa = "add -A";
        ap = "add -p";
        rf = "reflog";

        # checkout
        co  = "checkout";
        cob = "checkout -b";

        # commit
        cm  = "commit -m";
        ca  = "commit --amend";
        can = "commit --amend --no-edit";

        # stash
        ss = "stash save";
        sp = "stash pop";
        sl = "stash list";

        # rebase
        rbi = "rebase -i";
        rbc = "rebase --continue";
	      rba = "rebase --abort";

        # advanced
        pushf   = "push --force-with-lease --force-if-includes";
	      ll      = "log --graph --pretty='%Cred%h%Creset - %C(bold blue)<%an>%Creset %s%C(yellow)%d%Creset %Cgreen(%cr)' --abbrev-commit --date=relative";
        pp      = "!git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
        desc    = "\!git log --format=format:'- %s' --reverse origin/\"\${1:-master}\"..HEAD #";
        unstage = "reset HEAD --";
      };

      # difftastic = {
      #   enable = true;
      # };

      extraConfig = {
        init.defaultBranch = "main";
        # am.threeway = true;
        # apply.ignorewhitespace = "change";
        core.editor = "vim";
        fetch.prune = true;
        # help.autocorrect = -1;
        log = {
          abbrevcommit = true;
          decorate = "short";
        };
        pull = {
          ff = "only";
          rebase = true;
        };
        push = {
          autosetupremote = true;
          default = "current";
        };
        rebase = {
          autosquash = true;
          updaterefs = true;
          autoupdate = true;
          enabled = true;
        };
      };
    };
  };
}