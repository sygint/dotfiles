#!/usr/bin/env zsh
# install-githooks.sh: Symlink all hook scripts from scripts/git-hooks to .git/hooks

set -e
HOOKS_DIR="$(dirname $0)"
GIT_DIR="$(git rev-parse --show-toplevel)"
GIT_HOOKS="$GIT_DIR/.git/hooks"

for hook in $HOOKS_DIR/*; do
  hookname="$(basename $hook)"
  target="$GIT_HOOKS/$hookname"
  # Remove existing hook if it's a symlink or file
  if [[ -L "$target" || -f "$target" ]]; then
    rm -f "$target"
  fi
  ln -s "$hook" "$target"
  echo "Symlinked $hookname to $target"
done

echo "All hooks symlinked!"
