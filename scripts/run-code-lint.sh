#!/usr/bin/env bash
set -euo pipefail

# Pre-commit hook wrapper: run the code-lint helper with --fix for local commits.
# Exits non-zero if the helper reports errors (so pre-commit fails and prevents commit).

DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$DIR"

echo "[pre-commit] Running code-lint helper (auto-fix enabled)..."

if command -v bun >/dev/null 2>&1; then
  bun .claude/PAI/Tools/code-lint.ts --path . --format text --fix || EXIT=$?
else
  if command -v node >/dev/null 2>&1; then
    node .claude/PAI/Tools/code-lint.ts --path . --format text --fix || EXIT=$?
  else
    echo "[pre-commit] Error: neither 'bun' nor 'node' found in PATH."
    exit 2
  fi
fi

EXIT=${EXIT:-0}
if [ "$EXIT" -ne 0 ]; then
  echo "[pre-commit] code-lint reported issues. Fix them or commit with --no-verify."
  exit "$EXIT"
fi

echo "[pre-commit] code-lint completed successfully."
exit 0
