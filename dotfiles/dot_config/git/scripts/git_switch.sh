#!/bin/bash

# Git switch with autostashing
function git_sw() {
  if [[ -z "$1" ]]; then
    echo "[sw] No branch specified"
    return
  fi

  no_changes_msg=$(echo "No local changes to save")
  is_stashed=false
  current_branch=$(git branch --show-current)

  if [[ ! "$1" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    echo "[sw] Invalid branch name [$1]"
    return
  fi

  if [[ "$current_branch" == "$1" ]]; then
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

  stash_output="$(git stash -u)"
  stash_exit_code=$?
  if [[ "$stash_exit_code" -ne 0 ]]; then
    echo "[sw] Failed to stash changes"
    return
  fi

  if [[ "$stash_output" == "$no_changes_msg" ]]; then
    echo "[sw] No local changes to save"
  else
    is_stashed=true
    echo "[sw] Local changes stashed"
  fi

  git switch -q "$1" # Using quiet mode (-q) to suppress unnecessary output for cleaner logs

  if [[ "$is_stashed" == true ]]; then
    if git stash pop -q; then
      echo "[sw] Stash popped successfully"
    else
      echo "[sw] Failed to pop stash. You may need to resolve conflicts manually."
    fi
  else
    echo "[sw] No stash to apply"
  fi
}

# Call the function with the first argument passed to the script
git_sw "$1"