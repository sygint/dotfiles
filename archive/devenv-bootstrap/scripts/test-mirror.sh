#!/usr/bin/env bash
# Simple local test harness for scripts/mirror-to-github.sh
set -euo pipefail

echo "Running mirror script tests"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Determine the source mirror script path (absolute) before we cd anywhere
SRC_SCRIPT=$(realpath "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/mirror-to-github.sh")
if [[ ! -f "$SRC_SCRIPT" ]]; then
  echo "Source mirror script not found: $SRC_SCRIPT"
  exit 1
fi

# Test 1: Push to local bare remote (should push branch/tags)
REMOTE="$TMP/remote.git"
LOCAL="$TMP/local1"

mkdir -p "$REMOTE"
git init --bare "$REMOTE"

mkdir -p "$LOCAL"
cd "$LOCAL"
git init
cat > README.md <<'EOF'
hello
EOF
git add README.md
git commit -m 'initial commit'
git branch -M main

git remote add github "$REMOTE"

git tag -a v2.1.0 -m 'v2.1.0'

# Copy the script under scripts/ to mimic repo layout
mkdir -p scripts
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cp "$SRC_SCRIPT" ./scripts/mirror-to-github.sh || true

# Run the script (it should detect the remote and do a dry run by default - test both modes)

# Dry-run should show "Would push"
DRYOUT=$(./scripts/mirror-to-github.sh --dry-run 2>&1 || true)
if ! echo "$DRYOUT" | grep -q "\[DRY-RUN\]"; then
  echo "Dry-run did not report DRY-RUN: $DRYOUT"
  exit 1
fi

# Now run for real (pushing to local bare remote) - safe
./scripts/mirror-to-github.sh || true

# Ensure remote has refs
if ! git ls-remote "$REMOTE" | grep -q "refs/heads/main"; then
  echo "Remote doesn't have main after push"
  git ls-remote "$REMOTE"
  exit 1
fi

if ! git ls-remote "$REMOTE" | grep -q "refs/tags/v2.1.0"; then
  echo "Remote doesn't have tag v2.1.0 after push"
  git ls-remote "$REMOTE"
  exit 1
fi

echo "Test 1 passed"

# Test 2: Repo without remote -> dry-run -> show instructions & skip push
LOCAL2="$TMP/local2"
mkdir -p "$LOCAL2"
cd "$LOCAL2"
git init
cat > README.md <<'EOF'
hello2
EOF
git add README.md
git commit -m 'initial commit 2'
mkdir -p scripts
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cp "$SRC_SCRIPT" ./scripts/mirror-to-github.sh || true

OUT2=$(./scripts/mirror-to-github.sh --dry-run 2>&1 || true)
if ! echo "$OUT2" | grep -iq "No GitHub remote found"; then
  echo "Expected warning about missing GitHub remote: $OUT2"
  exit 1
fi

echo "Test 2 passed"

# Sanity
echo "All mirror script tests passed"
