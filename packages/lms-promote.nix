# lms-promote — discover models on cortex not yet in nix config, promote selected ones
#
# Usage:
#   lms-promote              # interactive: show diff, pick models to add
#   lms-promote --list       # just show what's on cortex vs what's in config
#   lms-promote --dry-run    # show what would be written without editing
#   lms-promote --url URL    # custom LM Studio API base (default: https://ai.cortex.home/v1)
#
# Workflow:
#   1. Queries cortex's LM Studio API for installed models
#   2. Parses models list from systems/cortex/default.nix
#   3. Shows unpromoted models (on server but not in config)
#   4. Lets you select which to add to the declarative config
#   5. Edits systems/cortex/default.nix in place
#
# After promoting, deploy with: harmonix deploy cortex
{ pkgs, ... }:

pkgs.writeShellScriptBin "lms-promote" ''
  set -euo pipefail

  # --- Config ---
  NIXOS_DIR="$HOME/.config/nixos"
  CORTEX_CONFIG="$NIXOS_DIR/systems/cortex/default.nix"
  BASE_URL="https://ai.cortex.home/v1"
  DRY_RUN=false
  LIST_ONLY=false

  # Colors
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  DIM='\033[2m'
  BOLD='\033[1m'
  NC='\033[0m'

  # --- Args ---
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list|-l)    LIST_ONLY=true; shift ;;
      --dry-run|-n) DRY_RUN=true; shift ;;
      --url)        BASE_URL="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: lms-promote [--list] [--dry-run] [--url BASE_URL]"
        echo ""
        echo "Discover models on cortex and promote them to nix config."
        echo ""
        echo "Options:"
        echo "  -l, --list      Show model diff only (no changes)"
        echo "  -n, --dry-run   Show what would be written without editing"
        echo "  --url URL       LM Studio API base URL (default: $BASE_URL)"
        echo ""
        echo "After promoting, deploy with: harmonix deploy cortex"
        exit 0
        ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  # --- Validate ---
  if [ ! -f "$CORTEX_CONFIG" ]; then
    echo -e "''${RED}Error: $CORTEX_CONFIG not found''${NC}" >&2
    exit 1
  fi

  # --- Query cortex ---
  echo -e "''${CYAN}Querying cortex at $BASE_URL ...''${NC}"

  # Get detailed model info via SSH (lms ls --json has richer data than /v1/models)
  REMOTE_JSON=$(ssh jarvis@192.168.1.7 lms ls --json 2>/dev/null) || {
    echo -e "''${RED}Error: Could not reach cortex via SSH''${NC}" >&2
    echo "Falling back to API..." >&2
    REMOTE_JSON=""
  }

  if [ -n "$REMOTE_JSON" ]; then
    # Rich format from lms ls --json
    REMOTE_MODELS=$(echo "$REMOTE_JSON" | ${pkgs.jq}/bin/jq -r '
      .[] | select(.type == "llm") |
      [.modelKey, .displayName, .paramsString // "?", .quantization.name // "?",
       ((.sizeBytes / 1073741824 * 10 | round) / 10 | tostring) + "GB"] |
      @tsv
    ')
  else
    # Fallback: API only (less detail)
    RESPONSE=$(${pkgs.curl}/bin/curl -sf --connect-timeout 5 "''${BASE_URL%/}/models" 2>/dev/null) || {
      echo -e "''${RED}Error: Could not reach LM Studio API at $BASE_URL''${NC}" >&2
      exit 1
    }
    REMOTE_MODELS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '
      .data[] | select(.id | test("embed"; "i") | not) |
      [.id, .id, "?", "?", "?"] | @tsv
    ')
  fi

  if [ -z "$REMOTE_MODELS" ]; then
    echo "No LLM models found on cortex."
    exit 0
  fi

  # --- Parse nix config ---
  # Extract the models list from the nix file (between models = [ and ];)
  NIX_MODELS=$(${pkgs.gnused}/bin/sed -n '/llmster\s*=\s*{/,/};/{
    /models\s*=\s*\[/,/\];/{
      /models\s*=\s*\[/d
      /\];/d
      s/^[[:space:]]*"//
      s/".*//
      /^#/d
      /^$/d
      p
    }
  }' "$CORTEX_CONFIG")

  # --- Diff ---
  echo ""
  echo -e "''${BOLD}=== Model Inventory ===''${NC}"
  echo ""

  # Track promoted and unpromoted
  PROMOTED=()
  UNPROMOTED_KEYS=()
  UNPROMOTED_DISPLAY=()

  while IFS=$'\t' read -r key display params quant size; do
    # Check if this modelKey matches any nix config entry
    # The nix config uses fuzzy names, so we check if the nix entry is a substring of the key
    # or if the key starts with the nix entry
    MATCHED=false
    while IFS= read -r nix_model; do
      [ -z "$nix_model" ] && continue
      # Normalize for comparison: lowercase both
      nix_lower=$(echo "$nix_model" | tr '[:upper:]' '[:lower:]')
      key_lower=$(echo "$key" | tr '[:upper:]' '[:lower:]')

      # Strategy 1: exact match or substring
      if [[ "$key_lower" == "$nix_lower" ]] || \
         [[ "$key_lower" == *"$nix_lower"* ]]; then
        MATCHED=true
        break
      fi

      # Strategy 2: token-based fuzzy match
      # Split nix search term into tokens on - and /
      # All tokens must appear in the modelKey (mimics LM Studio fuzzy search)
      ALL_TOKENS_MATCH=true
      for token in $(echo "$nix_lower" | tr '/-' '\n'); do
        [ -z "$token" ] && continue
        if [[ "$key_lower" != *"$token"* ]]; then
          ALL_TOKENS_MATCH=false
          break
        fi
      done
      if [ "$ALL_TOKENS_MATCH" = true ]; then
        MATCHED=true
        break
      fi
    done <<< "$NIX_MODELS"

    if [ "$MATCHED" = true ]; then
      PROMOTED+=("$key")
      echo -e "  ''${GREEN}✓''${NC} $display ''${DIM}($params, $quant, $size)''${NC}"
    else
      UNPROMOTED_KEYS+=("$key")
      UNPROMOTED_DISPLAY+=("$display ($params, $quant, $size)")
      echo -e "  ''${YELLOW}○''${NC} $display ''${DIM}($params, $quant, $size)''${NC}"
    fi
  done <<< "$REMOTE_MODELS"

  echo ""
  echo -e "  ''${GREEN}✓''${NC} = in nix config    ''${YELLOW}○''${NC} = on cortex only"
  echo ""
  echo -e "  ''${DIM}Declared: ''${#PROMOTED[@]}  |  Unpromoted: ''${#UNPROMOTED_KEYS[@]}''${NC}"

  # --- List only? ---
  if [ "$LIST_ONLY" = true ]; then
    exit 0
  fi

  # --- Nothing to promote? ---
  if [ ''${#UNPROMOTED_KEYS[@]} -eq 0 ]; then
    echo -e "''${GREEN}All models are already in nix config.''${NC}"
    exit 0
  fi

  # --- Select models to promote ---
  echo -e "''${BOLD}Select models to promote (space-separated numbers, 'a' for all, 'q' to quit):''${NC}"
  echo ""
  for i in "''${!UNPROMOTED_KEYS[@]}"; do
    echo -e "  ''${CYAN}$((i+1)))''${NC} ''${UNPROMOTED_DISPLAY[$i]}"
  done
  echo ""
  read -rp "> " SELECTION

  if [[ "$SELECTION" == "q" ]] || [[ -z "$SELECTION" ]]; then
    echo "Cancelled."
    exit 0
  fi

  SELECTED_KEYS=()
  if [[ "$SELECTION" == "a" ]]; then
    SELECTED_KEYS=("''${UNPROMOTED_KEYS[@]}")
  else
    for num in $SELECTION; do
      idx=$((num - 1))
      if [ "$idx" -ge 0 ] && [ "$idx" -lt "''${#UNPROMOTED_KEYS[@]}" ]; then
        SELECTED_KEYS+=("''${UNPROMOTED_KEYS[$idx]}")
      else
        echo -e "''${RED}Invalid selection: $num''${NC}" >&2
      fi
    done
  fi

  if [ ''${#SELECTED_KEYS[@]} -eq 0 ]; then
    echo "No valid models selected."
    exit 0
  fi

  # --- Build nix entries ---
  # For each selected model, ask for an optional comment
  NEW_ENTRIES=""
  for key in "''${SELECTED_KEYS[@]}"; do
    # Get display info
    info=$(echo "$REMOTE_JSON" | ${pkgs.jq}/bin/jq -r --arg k "$key" '
      .[] | select(.modelKey == $k) |
      (.paramsString // "?") + ", " + (.quantization.name // "?") + ", " +
      ((.sizeBytes / 1073741824 * 10 | round) / 10 | tostring) + "GB"
    ')
    echo ""
    echo -e "  ''${GREEN}+''${NC} $key ''${DIM}($info)''${NC}"
    read -rp "  Comment (enter to skip): " COMMENT

    if [ -n "$COMMENT" ]; then
      NEW_ENTRIES+="          \"$key\"  # $COMMENT"$'\n'
    else
      NEW_ENTRIES+="          \"$key\""$'\n'
    fi
  done

  # --- Edit nix config ---
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "''${YELLOW}Dry run — would add to $CORTEX_CONFIG:''${NC}"
    echo ""
    echo "$NEW_ENTRIES"
    exit 0
  fi

  # Insert new entries before the closing ]; of the models list
  # Find the line number of the ]; that closes the models list
  MODELS_START=$(${pkgs.gnugrep}/bin/grep -n 'models\s*=\s*\[' "$CORTEX_CONFIG" | head -1 | cut -d: -f1)
  MODELS_END=$(${pkgs.gawk}/bin/awk -v start="$MODELS_START" '
    NR > start && /\];/ { print NR; exit }
  ' "$CORTEX_CONFIG")

  if [ -z "$MODELS_END" ]; then
    echo -e "''${RED}Error: Could not find end of models list in $CORTEX_CONFIG''${NC}" >&2
    exit 1
  fi

  # Insert before the closing ];
  ${pkgs.gnused}/bin/sed -i "''${MODELS_END}i\\
$(echo "$NEW_ENTRIES" | ${pkgs.gnused}/bin/sed 's/$/\\/' | ${pkgs.gnused}/bin/sed '$ s/\\$//')" "$CORTEX_CONFIG"

  echo -e "''${GREEN}Added ''${#SELECTED_KEYS[@]} model(s) to $CORTEX_CONFIG''${NC}"
  echo ""
  echo "Next steps:"
  echo -e "  1. Review:  ''${DIM}git diff systems/cortex/default.nix''${NC}"
  echo -e "  2. Deploy:  ''${DIM}harmonix deploy cortex''${NC}"
  echo -e "  3. Commit:  ''${DIM}git add systems/cortex/default.nix && git commit''${NC}"
''
