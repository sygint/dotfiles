# opencode-lmstudio-sync — queries LM Studio API and updates opencode.json models
#
# Usage:
#   opencode-lmstudio-sync              # sync from cortex (default)
#   opencode-lmstudio-sync --dry-run    # show what would change without writing
#   opencode-lmstudio-sync --url http://localhost:1234/v1  # custom LM Studio URL
#
# The script:
#   1. Queries the LM Studio /v1/models endpoint
#   2. Reads the existing opencode.json dotfile
#   3. Adds any new models, removes models no longer on the server
#   4. Preserves manually-set "limit" values (context/output) for existing models
#   5. Writes the updated config — no nix rebuild needed
{ pkgs, ... }:

pkgs.writeShellScriptBin "opencode-lmstudio-sync" ''
  set -euo pipefail

  # Defaults
  CONFIG_FILE="$HOME/.config/nixos/dotfiles/.config/opencode/opencode.json"
  BASE_URL="http://192.168.1.7:1234/v1"
  DRY_RUN=false

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true; shift ;;
      --url) BASE_URL="$2"; shift 2 ;;
      --config) CONFIG_FILE="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: opencode-lmstudio-sync [--dry-run] [--url BASE_URL] [--config FILE]"
        echo ""
        echo "Syncs available LM Studio models into opencode.json."
        echo ""
        echo "Options:"
        echo "  --dry-run    Show what would change without writing"
        echo "  --url URL    LM Studio API base URL (default: http://192.168.1.7:1234/v1)"
        echo "  --config F   Path to opencode.json (default: ~/.config/nixos/dotfiles/.config/opencode/opencode.json)"
        exit 0
        ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  API_URL="''${BASE_URL%/}/models"

  echo "Querying LM Studio at $API_URL ..."

  RESPONSE=$(${pkgs.curl}/bin/curl -sf --connect-timeout 5 "$API_URL" 2>/dev/null) || {
    echo "Error: Could not reach LM Studio at $API_URL" >&2
    echo "Is LM Studio running?" >&2
    exit 1
  }

  # Extract model IDs, filtering out embedding models
  REMOTE_MODELS=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '
    .data[].id
    | select(test("embed"; "i") | not)
  ' 2>/dev/null) || {
    echo "Error: Unexpected API response format" >&2
    exit 1
  }

  if [ -z "$REMOTE_MODELS" ]; then
    echo "No models found on LM Studio server."
    exit 0
  fi

  MODEL_COUNT=$(echo "$REMOTE_MODELS" | wc -l)
  echo "Found $MODEL_COUNT models on server."

  # Read existing config or create a base structure
  if [ -f "$CONFIG_FILE" ]; then
    EXISTING=$(${pkgs.jq}/bin/jq '.' "$CONFIG_FILE")
  else
    EXISTING='{"$schema":"https://opencode.ai/config.json","provider":{}}'
    echo "No existing config found, creating new one."
  fi

  # Build the new models object, preserving existing limit settings
  NEW_MODELS=$(echo "$REMOTE_MODELS" | ${pkgs.jq}/bin/jq -Rn --argjson existing "$EXISTING" '
    # Title case helper: capitalize first letter of each word
    def title_case:
      split(" ") | map(
        if length > 0 then
          (.[0:1] | ascii_upcase) + .[1:]
        else . end
      ) | join(" ");

    # Collect existing models and their limits (check both provider keys)
    ($existing.provider.lmstudio.models // $existing.provider.openai.models // {}) as $old_models |

    # Read all model IDs from stdin
    [inputs | select(length > 0)] |

    # Build new models object
    reduce .[] as $id ({};
      # Generate display name: last path component, hyphens to spaces, title case
      ($id | split("/") | last | gsub("-"; " ") | title_case) as $display_name |

      # Check if existing model has limits to preserve
      (if $old_models[$id].limit then
        { name: $display_name, limit: $old_models[$id].limit }
      else
        { name: $display_name }
      end) as $model_entry |

      . + { ($id): $model_entry }
    )
  ') || {
    echo "Error: Failed to build models object" >&2
    exit 1
  }

  # Merge into the config, using lmstudio provider key (per opencode docs)
  UPDATED=$(echo "$EXISTING" | ${pkgs.jq}/bin/jq --argjson models "$NEW_MODELS" --arg url "$BASE_URL" '
    # Remove old openai provider if it was our LM Studio config
    (if .provider.openai.name == "LM Studio" then del(.provider.openai) else . end) |

    # Set up lmstudio provider
    .provider.lmstudio = {
      npm: "@ai-sdk/openai-compatible",
      name: "LM Studio",
      options: {
        baseURL: $url,
        apiKey: "lm-studio"
      },
      models: $models
    }
  ')

  if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "=== Dry run — would write to $CONFIG_FILE ==="
    echo "$UPDATED" | ${pkgs.jq}/bin/jq '.'
    echo ""

    # Show diff of models
    OLD_IDS=$(echo "$EXISTING" | ${pkgs.jq}/bin/jq -r '(.provider.lmstudio.models // .provider.openai.models // {}) | keys[]' 2>/dev/null | sort)
    NEW_IDS=$(echo "$NEW_MODELS" | ${pkgs.jq}/bin/jq -r 'keys[]' | sort)

    ADDED=$(comm -13 <(echo "$OLD_IDS") <(echo "$NEW_IDS"))
    REMOVED=$(comm -23 <(echo "$OLD_IDS") <(echo "$NEW_IDS"))

    if [ -n "$ADDED" ]; then
      echo "Models to add:"
      echo "$ADDED" | while read -r m; do echo "  + $m"; done
    fi
    if [ -n "$REMOVED" ]; then
      echo "Models to remove:"
      echo "$REMOVED" | while read -r m; do echo "  - $m"; done
    fi
    if [ -z "$ADDED" ] && [ -z "$REMOVED" ]; then
      echo "No model changes."
    fi
  else
    # Write the updated config
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "$UPDATED" | ${pkgs.jq}/bin/jq '.' > "$CONFIG_FILE"

    echo ""
    echo "Updated $CONFIG_FILE with $MODEL_COUNT models."
    echo "Models:"
    echo "$NEW_MODELS" | ${pkgs.jq}/bin/jq -r 'keys[] | "  - " + .'
    echo ""
    echo "Changes take effect immediately — no rebuild needed."
  fi
''
