{ gitUsername, gitEmail }:
''
[user]
  name = ${gitUsername}
  email = ${gitEmail}

[alias]
  s = status
  l = log

  ap = add -p
  aa = add -A

  b = branch
  bd = branch -d

  ss = stash save
  sp = stash pop
  sl = stash list

  co = checkout
  cob = checkout -b

  cm = commit -m
  ca = commit --amend
  can = commit --amend --no-edit

  rb = rebase
  rbi = rebase -i
  rba = rebase --abort
  rbc = rebase --continue

  cp = cherry-pick
  cpa = cherry-pick --abort
  cpc = cherry-pick --continue
  cps = cherry-pick --skip

  unstage = restore --staged

  dm = diff --color-moved=plain
  ds = diff --staged

  p = pull
  pushf = push --force-with-lease --force-if-includes
  pp = !git push --set-upstream origin $(git branch --show-current)

  desc = !sh -c 'git log --format=format:" - %s" --reverse origin/''${1:-master}..HEAD' --

  rf = reflog

  cgl = config --global --list
  whoami = !git config --get user.name && git config --get user.email

  ll = log --graph --pretty=format:'%Cred%h%Creset %C(bold blue)%an%Creset%C(yellow)%d%Creset %Cgreen(%cr)%Creset%n%B' --stat
  lll = log --no-decorate --format=medium

  sw = !sh /home/syg/.config/git/scripts/git_switch.sh

  rbdev = !CURRENT_BRANCH=$(git branch --show-current) git rebase origin/dev --autostash
  pdev = !CURRENT_BRANCH=$(git branch --show-current) git pull origin dev --autostash

  clean-branches = !git fetch -p && git remote prune origin && git branch --merged origin/dev | grep -v "dev" | xargs git branch -d
  list-gone-branches = !git remote prune origin && git branch -vv |  grep ': gone]' | awk '{print $1}'
  delete-gone-branches = !git remote prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -d

[core]
  editor = code --wait --new-window
  # pager = delta
  abbrev = auto
  whitespace = -space-before-tab,tab-in-indent,blank-at-eol

[status]
  short = true
  branch = true
  showUntrackedFiles = all # can be slow
  showStash = true

[fetch]
  prune = true

[push]
  autoSetupRemote = true
  default = current

[branch]
  autoSetupMerge = simple

[init]
  defaultBranch = main

[interactive]
  diffFilter = delta --color-only

[delta]
  nagivate = true # use n and N to move between diff sections
  side-by-side = true
  # delta detected terminal colors automatically; set one of these to disable auto-detection
  # dark = true
  # light = true

[merge]
  conflictstyle = diff3

[diff]
  colorMoved = default
  colormovedws = allow-indentation-change

[sequence]
  editor = interactive-rebase-tool

[rebase]
  autoStash = true
  autoupdate = true
  enabled = true
  updaterefs = true

[pull]
  ff = only
  rebase = true

[log]
  abbrevcommit = true

# [submodule]
#   recurse = true

[format]
  pretty = oneline
''
