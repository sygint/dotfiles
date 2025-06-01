#!/bin/bash

# Git switch with autostashing
function git_sw() {
  if [[ -z "$1" ]]; then
    echo "[sw] No branch specified"
    return
  fi

  no_local_changes_to_save=$(echo "No local changes to save")
  is_stashed=false

  if [[ "$(git branch --show-current)" == "$1" ]]; then
    echo "[sw] Already on branch [$1]"
    return
  fi

  if git rev-parse --verify --quiet refs/heads/"$1" >/dev/null; then
    branch_type=local
  elif git rev-parse --verify --quiet refs/remotes/origin/"$1" >/dev/null; then
    branch_type=remote
  else
    echo "[sw] Branch [$1] does not exist"
    return
  fi

  echo "[sw] Switching to branch [$1]..."
  stash_output="$(git stash -u)"
  if [[ "$stash_output" == "$no_local_changes_to_save" ]]; then
    echo "[sw] No local changes to save"
  else
    is_stashed=true
    echo "[sw] Local changes stashed"
  fi

  git switch "$1" -q
  echo "[sw] Switched to branch [$1]"

  if $is_stashed; then
    git stash pop -q
    echo "[sw] Stash popped successfully"
  else
    echo "[sw] No stash to apply"
  fi
}

# Call the function with the first argument passed to the script
git_sw "$1"