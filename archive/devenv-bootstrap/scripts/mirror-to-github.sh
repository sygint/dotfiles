#!/usr/bin/env bash
set -euo pipefail

# mirror-to-github.sh - Mirror this repo to GitHub and optionally create a release
# Usage: scripts/mirror-to-github.sh [--create-repo] [--visibility public|private]

REPO_NAME="devenv-bootstrap"
GITHUB_REMOTE="github"
VISIBILITY="public"
CREATE_REPO=false
DRYRUN=false

print_help() {
  cat <<'EOF'
Usage: mirror-to-github.sh [options]

Options:
  --create-repo        Create the GitHub repository if missing (requires gh authentication)
  --visibility <opt>   Visibility: public (default) or private
  -h, --help            Show this help

What the script does:
  - Adds a 'github' remote if missing
  - Optionally creates a GitHub repository with `gh` (if --create-repo provided)
  - Pushes the main branch and tags
  - Creates a GitHub release for tag v2.1.0 if 'gh' is available

EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --create-repo)
      CREATE_REPO=true
      shift
      ;;
    --dry-run)
      DRYRUN=true
      shift
      ;;
    --visibility)
      VISIBILITY="$2"; shift 2
      ;;
    -h|--help)
      print_help; exit 0
      ;;
    *)
      echo "Unknown argument: $1"; print_help; exit 1
      ;;
  esac
done

# Ensure running from repository root
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$SCRIPT_DIR"

# Prefer actual git repo root if available
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  SCRIPT_DIR=$(git rev-parse --show-toplevel)
  cd "$SCRIPT_DIR"
fi

# Ensure there's a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "This script must be run from within a git repository"
  exit 1
fi

# Add GitHub remote if missing
if git remote get-url "$GITHUB_REMOTE" >/dev/null 2>&1; then
  echo "GitHub remote '$GITHUB_REMOTE' already configured: $(git remote get-url $GITHUB_REMOTE)"
else
  # If gh is available and we requested to create repo, use it to create repo
  if $CREATE_REPO && command -v gh >/dev/null 2>&1; then
    echo "Creating GitHub repo $REPO_NAME ($VISIBILITY)"
    gh repo create "syg/$REPO_NAME" --$VISIBILITY --source=. --remote="$GITHUB_REMOTE" --push || true
  else
    # Fallback: ask for manual remote setup
    echo "No GitHub remote found and 'gh' is either not installed or not used."
    echo "If you want to create the repo automatically, re-run with --create-repo and ensure 'gh' is authenticated."
    echo "Otherwise, add a remote with:"
    echo "  git remote add $GITHUB_REMOTE git@github.com:syg/$REPO_NAME.git"
  fi
fi

# Push to GitHub remote if configured
if git remote get-url "$GITHUB_REMOTE" >/dev/null 2>&1; then
  if [[ "$DRYRUN" == "true" ]]; then
    echo "[DRY-RUN] Would push main and tags to $GITHUB_REMOTE"
    git remote get-url "$GITHUB_REMOTE"
  else
    echo "Pushing main and tags to $GITHUB_REMOTE"
    git push --set-upstream "$GITHUB_REMOTE" main || true
    git push "$GITHUB_REMOTE" --tags || true
  fi
else
  echo "No GitHub remote configured, skipping push"
fi

# Create GitHub release if gh is available
if command -v gh >/dev/null 2>&1; then
  # Create a release for v2.1.0 if it exists
  if git rev-parse v2.1.0 >/dev/null 2>&1; then
    if [[ "$DRYRUN" == "true" ]]; then
      echo "[DRY-RUN] Would create GitHub release v2.1.0"
    else
      echo "Creating GitHub release v2.1.0"
      gh release create v2.1.0 --title "v2.1.0" --notes "v2.1.0 - initial release" || true
    fi
  else
    echo "Tag v2.1.0 not found locally, skipping release creation"
  fi
else
  echo "'gh' CLI not available. To create a GitHub release, install gh and run:"
  echo "  gh release create v2.1.0 --title 'v2.1.0' --notes 'v2.1.0 - initial release'"
fi

echo "Done. Remotes:"
git remote -v
