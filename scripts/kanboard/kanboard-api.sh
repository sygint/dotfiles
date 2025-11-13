#!/usr/bin/env bash
# Kanboard API helper script
# Usage: kanboard-api.sh <method> [params]

set -euo pipefail

# Load environment variables from .env if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ -f "$ENV_FILE" ]]; then
    # Export variables from .env file
    set -a
    # shellcheck source=../.env
    source "$ENV_FILE"
    set +a
fi

# Configuration
KANBOARD_URL="${KANBOARD_URL:-http://localhost/jsonrpc.php}"
KANBOARD_USER="${KANBOARD_USER:-jsonrpc}"
KANBOARD_TOKEN="${KANBOARD_TOKEN:-}"

# Check if API token is set
if [[ -z "$KANBOARD_TOKEN" ]]; then
    echo "Error: KANBOARD_TOKEN environment variable not set"
    echo "Get your API token from: http://localhost/settings/api"
    echo "Then: export KANBOARD_TOKEN='your-token-here'"
    exit 1
fi

# Generate random ID for JSON-RPC
REQUEST_ID=$(date +%s)

# Parse arguments
METHOD="${1:-}"
if [[ -z "$METHOD" ]]; then
    echo "Usage: $0 <method> [params-as-json]"
    echo ""
    echo "Examples:"
    echo "  $0 getAllProjects"
    echo "  $0 createProject '{\"name\":\"My Project\"}'"
    echo "  $0 createTask '{\"project_id\":1,\"title\":\"My Task\"}'"
    echo "  $0 getAllTasks '{\"project_id\":1,\"status_id\":1}'"
    echo ""
    echo "Set KANBOARD_TOKEN environment variable first!"
    exit 1
fi

# Parse params (optional)
PARAMS="${2:-{}}"

# Build the JSON request (compact, no newlines)
JSON_REQUEST='{"jsonrpc":"2.0","method":"'${METHOD}'","id":'${REQUEST_ID}',"params":'${PARAMS}'}'

# Make API call
curl -s -u "${KANBOARD_USER}:${KANBOARD_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${JSON_REQUEST}" \
    "${KANBOARD_URL}" | jq '.'
