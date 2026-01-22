#!/usr/bin/env bash
# Vikunja CLI wrapper for task management
# Usage: vikunja-cli <command> [args]

set -euo pipefail

VIKUNJA_URL="${VIKUNJA_URL:-http://192.168.1.22:3456/api/v1}"
TOKEN_FILE="${HOME}/.config/vikunja/token"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get or create API token
get_token() {
    if [[ -f "$TOKEN_FILE" ]]; then
        cat "$TOKEN_FILE"
    else
        echo -e "${YELLOW}No API token found. Please login first: vikunja-cli login${NC}" >&2
        exit 1
    fi
}

# API request helper
api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local token
    token=$(get_token)
    
    if [[ -n "$data" ]]; then
        curl -s -X "$method" "${VIKUNJA_URL}${endpoint}" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${VIKUNJA_URL}${endpoint}" \
            -H "Authorization: Bearer $token"
    fi
}

# Login and save token
cmd_login() {
    local username password
    read -rp "Username: " username
    read -rsp "Password: " password
    echo
    
    local response
    response=$(curl -s -X POST "${VIKUNJA_URL}/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$username\",\"password\":\"$password\"}")
    
    local token
    token=$(echo "$response" | jq -r '.token // empty')
    
    if [[ -n "$token" ]]; then
        mkdir -p "$(dirname "$TOKEN_FILE")"
        echo "$token" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        echo -e "${GREEN}✓ Logged in successfully${NC}"
    else
        echo -e "${RED}✗ Login failed: $(echo "$response" | jq -r '.message // "Unknown error"')${NC}"
        exit 1
    fi
}

# List projects
cmd_projects() {
    echo -e "${BLUE}Projects:${NC}"
    api GET "/projects" | jq -r '.[] | "  [\(.id)] \(.title)"'
}

# List tasks in a project
cmd_tasks() {
    local project_id="${1:-}"
    
    if [[ -z "$project_id" ]]; then
        echo "Usage: vikunja-cli tasks <project_id>"
        echo "Run 'vikunja-cli projects' to see project IDs"
        exit 1
    fi
    
    echo -e "${BLUE}Tasks in project $project_id:${NC}"
    api GET "/projects/$project_id/tasks" | jq -r '.[] | 
        (if .done then "  [x]" else "  [ ]" end) + " [\(.id)] \(.title)" + 
        (if .due_date != "0001-01-01T00:00:00Z" then " (due: \(.due_date | split("T")[0]))" else "" end)'
}

# Add a task
cmd_add() {
    local project_id="${1:-}"
    local title="${2:-}"
    
    if [[ -z "$project_id" || -z "$title" ]]; then
        echo "Usage: vikunja-cli add <project_id> \"<task title>\""
        exit 1
    fi
    
    local response
    response=$(api PUT "/projects/$project_id/tasks" "{\"title\":\"$title\"}")
    
    local task_id
    task_id=$(echo "$response" | jq -r '.id // empty')
    
    if [[ -n "$task_id" ]]; then
        echo -e "${GREEN}✓ Created task [$task_id]: $title${NC}"
    else
        echo -e "${RED}✗ Failed to create task${NC}"
        echo "$response" | jq .
        exit 1
    fi
}

# Complete a task
cmd_done() {
    local task_id="${1:-}"
    
    if [[ -z "$task_id" ]]; then
        echo "Usage: vikunja-cli done <task_id>"
        exit 1
    fi
    
    local response
    response=$(api POST "/tasks/$task_id" '{"done":true}')
    
    if echo "$response" | jq -e '.done == true' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Task $task_id marked complete${NC}"
    else
        echo -e "${RED}✗ Failed to complete task${NC}"
        exit 1
    fi
}

# Uncomplete a task
cmd_undone() {
    local task_id="${1:-}"
    
    if [[ -z "$task_id" ]]; then
        echo "Usage: vikunja-cli undone <task_id>"
        exit 1
    fi
    
    api POST "/tasks/$task_id" '{"done":false}' > /dev/null
    echo -e "${GREEN}✓ Task $task_id marked incomplete${NC}"
}

# Delete a task
cmd_delete() {
    local task_id="${1:-}"
    
    if [[ -z "$task_id" ]]; then
        echo "Usage: vikunja-cli delete <task_id>"
        exit 1
    fi
    
    api DELETE "/tasks/$task_id" > /dev/null
    echo -e "${GREEN}✓ Task $task_id deleted${NC}"
}

# Create a project
cmd_create_project() {
    local title="${1:-}"
    
    if [[ -z "$title" ]]; then
        echo "Usage: vikunja-cli create-project \"<project title>\""
        exit 1
    fi
    
    local response
    response=$(api PUT "/projects" "{\"title\":\"$title\"}")
    
    local project_id
    project_id=$(echo "$response" | jq -r '.id // empty')
    
    if [[ -n "$project_id" ]]; then
        echo -e "${GREEN}✓ Created project [$project_id]: $title${NC}"
    else
        echo -e "${RED}✗ Failed to create project${NC}"
        exit 1
    fi
}

# Show help
cmd_help() {
    cat << EOF
${BLUE}Vikunja CLI - Task Management${NC}

${YELLOW}Usage:${NC} vikunja-cli <command> [args]

${YELLOW}Commands:${NC}
  login                         Login to Vikunja
  projects                      List all projects
  tasks <project_id>            List tasks in a project
  add <project_id> "<title>"    Add a new task
  done <task_id>                Mark task complete
  undone <task_id>              Mark task incomplete
  delete <task_id>              Delete a task
  create-project "<title>"      Create a new project

${YELLOW}Examples:${NC}
  vikunja-cli login
  vikunja-cli projects
  vikunja-cli tasks 1
  vikunja-cli add 1 "Fix the bug"
  vikunja-cli done 42

${YELLOW}Environment:${NC}
  VIKUNJA_URL    API base URL (default: http://192.168.1.22:3456/api/v1)
EOF
}

# Main
case "${1:-help}" in
    login) cmd_login ;;
    projects) cmd_projects ;;
    tasks) cmd_tasks "${2:-}" ;;
    add) cmd_add "${2:-}" "${3:-}" ;;
    done) cmd_done "${2:-}" ;;
    undone) cmd_undone "${2:-}" ;;
    delete) cmd_delete "${2:-}" ;;
    create-project) cmd_create_project "${2:-}" ;;
    help|--help|-h) cmd_help ;;
    *) echo "Unknown command: $1"; cmd_help; exit 1 ;;
esac
