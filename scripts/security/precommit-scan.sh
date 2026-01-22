#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PATTERN_FILE="$REPO_ROOT/scripts/security/patterns/high-risk-patterns.txt"
ALLOWLIST_FILE="$REPO_ROOT/scripts/security/patterns/allowlist.txt"

if [[ ${SKIP_SECRET_SCAN:-0} == 1 ]]; then
  echo "[secret-scan] Skipped (SKIP_SECRET_SCAN=1)" >&2
  exit 0
fi

if [[ ! -f "$PATTERN_FILE" ]]; then
  echo "[secret-scan] Pattern file missing: $PATTERN_FILE" >&2
  exit 1
fi

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)
if [[ -z "$STAGED_FILES" ]]; then
  echo "[secret-scan] No staged files"
  exit 0
fi

# Filter out binary files
TEXT_FILES=()
while IFS= read -r f; do
  [[ ! -f "$f" ]] && continue
  if grep -Iq . "$f"; then
    TEXT_FILES+=("$f")
  fi
done <<<"$STAGED_FILES"

if [[ ${#TEXT_FILES[@]} -eq 0 ]]; then
  echo "[secret-scan] Only binary files staged; skipping"
  exit 0
fi

echo "[secret-scan] Scanning ${#TEXT_FILES[@]} staged text files"

tmp_matches=$(mktemp)
trap 'rm -f "$tmp_matches" "$tmp_detect" "$tmp_truffle"' EXIT

# Load patterns (ignore commented lines)
mapfile -t PATTERNS < <(grep -vE '^\s*#' "$PATTERN_FILE" | sed '/^\s*$/d')
if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  echo "[secret-scan] No patterns loaded" >&2
  exit 0
fi

PATTERN_REGEX=$(printf '%s|' "${PATTERNS[@]}")
PATTERN_REGEX="${PATTERN_REGEX%|}"

grep -EnIH -- "${PATTERN_REGEX}" "${TEXT_FILES[@]}" | grep -v -F -f "$ALLOWLIST_FILE" >"$tmp_matches" || true

FOUND=0
if [[ -s "$tmp_matches" ]]; then
  echo "[secret-scan] Pattern matches (potential secrets):"
  cat "$tmp_matches"
  FOUND=1
fi

# Detect-secrets (if available)
tmp_detect=$(mktemp)
if command -v detect-secrets >/dev/null 2>&1; then
  detect-secrets scan "${TEXT_FILES[@]}" > "$tmp_detect" || true
  # crude check for findings
  if grep -q '"results": {' "$tmp_detect" && ! grep -q '"results": {}' "$tmp_detect"; then
    echo "[secret-scan] detect-secrets findings:" >&2
    python - <<'PY' "$tmp_detect"
import json,sys
data=json.load(open(sys.argv[1]))
for path, findings in data.get('results', {}).items():
  for f in findings:
    print(f"{path}:{f['line_number']} {f['type']}")
PY
    FOUND=1
  fi
else
  echo "[secret-scan] detect-secrets not available" >&2
fi

# Trufflehog (fast mode) - scan only changed files if available
tmp_truffle=$(mktemp)
if command -v trufflehog >/dev/null 2>&1; then
  # Use filesystem mode limited to staged files
  # Create a temp directory with copies to limit scope
  TMP_DIR=$(mktemp -d)
  for f in "${TEXT_FILES[@]}"; do
    mkdir -p "$TMP_DIR/$(dirname "$f")"
    cp "$f" "$TMP_DIR/$f"
  done
    if trufflehog filesystem --only-verified "$TMP_DIR" > "$tmp_truffle" 2>&1; then
      if grep -q 'Verified' "$tmp_truffle"; then
        echo "[secret-scan] trufflehog verified secrets:" >&2
        grep 'Verified' "$tmp_truffle"
        FOUND=1
      else
        echo "[secret-scan] trufflehog: no verified secrets"
      fi
    else
      echo "[secret-scan] trufflehog error (non-blocking)" >&2
    fi
  rm -rf "$TMP_DIR"
else
  echo "[secret-scan] trufflehog not available" >&2
fi

if [[ $FOUND -eq 1 ]]; then
  echo "[secret-scan] ✖ Secret scan FAILED. Use SKIP_SECRET_SCAN=1 to override (not recommended)." >&2
  exit 1
fi

echo "[secret-scan] ✓ Clean"
exit 0
