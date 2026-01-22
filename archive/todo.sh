#!/usr/bin/env bash
# Simple todo CLI for Vikunja
# Usage: todo [command] [args]

set -euo pipefail

VIKUNJA_URL="${VIKUNJA_URL:-http://192.168.1.22:3456/api/v1}"
TOKEN_FILE="${HOME}/.config/vikunja/token"
DEFAULT_PROJECT="${VIKUNJA_DEFAULT_PROJECT:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

get_token() {
    if [[ -f "$TOKEN_FILE" ]]; then
        cat "$TOKEN_FILE"
    else
        echo -e "${RED}Not logged in. Run: todo login${NC}" >&2
        exit 1
    fi
}

api() {
    local method="$1" endpoint="$2" data="${3:-}"
    local token=$(get_token)
    
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

# Get project ID by name (fuzzy match)
get_project_id() {
    local name="$1"
    api GET "/projects" | jq -r ".[] | select(.title | ascii_downcase | contains(\"$(echo "$name" | tr '[:upper:]' '[:lower:]')\")) | .id" | head -1
}

# Get default project (first non-Inbox, or Inbox if only one)
get_default_project() {
    if [[ -n "$DEFAULT_PROJECT" ]]; then
        get_project_id "$DEFAULT_PROJECT"
    else
        # Get first project that's not Inbox, or Inbox if it's the only one
        api GET "/projects" | jq -r 'if length == 1 then .[0].id else (.[] | select(.title != "Inbox") | .id) end' | head -1
    fi
}

cmd_login() {
    echo -n "Username: "
    read -r username
    echo -n "Password: "
    read -rs password
    echo
    
    local response=$(curl -s -X POST "${VIKUNJA_URL}/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$username\",\"password\":\"$password\"}")
    
    local token=$(echo "$response" | jq -r '.token // empty')
    
    if [[ -n "$token" ]]; then
        mkdir -p "$(dirname "$TOKEN_FILE")"
        echo "$token" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        echo -e "${GREEN}✓ Logged in${NC}"
    else
        echo -e "${RED}✗ Login failed${NC}"
        exit 1
    fi
}

# List all todos (optionally filter by project)
cmd_list() {
    local project_filter="${1:-}"
    local project_id=""
    
    if [[ -n "$project_filter" ]]; then
        project_id=$(get_project_id "$project_filter")
        if [[ -z "$project_id" ]]; then
            echo -e "${RED}Project not found: $project_filter${NC}"
            exit 1
        fi
    fi
    
    # Get all projects and their tasks
    local projects=$(api GET "/projects")
    
    echo "$projects" | jq -r '.[] | "\(.id)|\(.title)"' | while IFS='|' read -r pid pname; do
        if [[ -n "$project_id" && "$pid" != "$project_id" ]]; then
            continue
        fi
        
        local tasks=$(api GET "/projects/$pid/tasks")
        local task_count=$(echo "$tasks" | jq 'length')
        
        if [[ "$task_count" -gt 0 ]]; then
            echo -e "\n${BLUE}═══ $pname ═══${NC}"
            echo "$tasks" | jq -r '.[] | 
                (if .done then "  \u001b[32m✓\u001b[0m" else "  \u001b[2m○\u001b[0m" end) + 
                " \u001b[2m[\(.id)]\u001b[0m " + 
                (if .done then "\u001b[9m\(.title)\u001b[0m" else .title end) +
                (if .due_date != "0001-01-01T00:00:00Z" then " \u001b[33m(\(.due_date | split("T")[0]))\u001b[0m" else "" end)'
        fi
    done
    echo
}

# Add a todo
cmd_add() {
    local title="$*"
    
    if [[ -z "$title" ]]; then
        echo "Usage: todo add <task title>"
        echo "       todo add -p <project> <task title>"
        exit 1
    fi
    
    local project_id=""
    
    # Check for -p project flag
    if [[ "$1" == "-p" ]]; then
        shift
        local project_name="$1"
        shift
        title="$*"
        project_id=$(get_project_id "$project_name")
        if [[ -z "$project_id" ]]; then
            echo -e "${RED}Project not found: $project_name${NC}"
            exit 1
        fi
    else
        project_id=$(get_default_project)
    fi
    
    if [[ -z "$project_id" ]]; then
        echo -e "${RED}No project found. Create one first: todo project new <name>${NC}"
        exit 1
    fi
    
    local response=$(api PUT "/projects/$project_id/tasks" "{\"title\":\"$title\"}")
    local task_id=$(echo "$response" | jq -r '.id // empty')
    
    if [[ -n "$task_id" ]]; then
        echo -e "${GREEN}✓${NC} Added: $title ${DIM}[$task_id]${NC}"
    else
        echo -e "${RED}✗ Failed to add task${NC}"
        exit 1
    fi
}

# Mark task done
cmd_done() {
    local task_id="$1"
    
    if [[ -z "$task_id" ]]; then
        echo "Usage: todo done <task_id>"
        exit 1
    fi
    
    api POST "/tasks/$task_id" '{"done":true}' > /dev/null
    echo -e "${GREEN}✓${NC} Completed task $task_id"
}

# Mark task not done
cmd_undo() {
    local task_id="$1"
    
    if [[ -z "$task_id" ]]; then
        echo "Usage: todo undo <task_id>"
        exit 1
    fi
    
    api POST "/tasks/$task_id" '{"done":false}' > /dev/null
    echo -e "${YELLOW}○${NC} Reopened task $task_id"
}

# Delete a task
cmd_rm() {
    local task_id="$1"
    
    if [[ -z "$task_id" ]]; then
        echo "Usage: todo rm <task_id>"
        exit 1
    fi
    
    api DELETE "/tasks/$task_id" > /dev/null
    echo -e "${RED}✗${NC} Deleted task $task_id"
}

# Project management
cmd_project() {
    local subcmd="${1:-list}"
    shift || true
    
    case "$subcmd" in
        list|ls)
            echo -e "${BLUE}Projects:${NC}"
            api GET "/projects" | jq -r '.[] | "  [\(.id)] \(.title)"'
            ;;
        new|create|add)
            local name="$*"
            if [[ -z "$name" ]]; then
                echo "Usage: todo project new <name>"
                exit 1
            fi
            local response=$(api PUT "/projects" "{\"title\":\"$name\"}")
            local pid=$(echo "$response" | jq -r '.id // empty')
            if [[ -n "$pid" ]]; then
                echo -e "${GREEN}✓${NC} Created project: $name ${DIM}[$pid]${NC}"
            else
                echo -e "${RED}✗ Failed${NC}"
                exit 1
            fi
            ;;
        rm|delete)
            local pid="$1"
            if [[ -z "$pid" ]]; then
                echo "Usage: todo project rm <project_id>"
                exit 1
            fi
            api DELETE "/projects/$pid" > /dev/null
            echo -e "${RED}✗${NC} Deleted project $pid"
            ;;
        *)
            echo "Usage: todo project [list|new|rm]"
            ;;
    esac
}

cmd_help() {
    cat << 'EOF'
todo - Simple task management

USAGE:
    todo                     List all todos
    todo <project>           List todos in project
    todo add <title>         Add todo to default project
    todo add -p proj <title> Add todo to specific project
    todo done <id>           Mark complete
    todo undo <id>           Mark incomplete
    todo rm <id>             Delete todo

    todo project             List projects
    todo project new <name>  Create project
    todo project rm <id>     Delete project

    todo login               Login to Vikunja

EXAMPLES:
    todo                         # Show all todos
    todo nixos                   # Show todos in "NixOS" project
    todo add Fix the bug         # Add to default project
    todo add -p work Call mom    # Add to "work" project
    todo done 42                 # Complete task 42

ENV:
    VIKUNJA_DEFAULT_PROJECT  Default project name for 'todo add'
EOF
}

# Main
case "${1:-}" in
    "") cmd_list ;;
    login) cmd_login ;;
    add) shift; cmd_add "$@" ;;
    done) cmd_done "${2:-}" ;;
    undo) cmd_undo "${2:-}" ;;
    rm|delete) cmd_rm "${2:-}" ;;
    project|proj|p) shift; cmd_project "$@" ;;
    help|--help|-h) cmd_help ;;
    *)
        # Check if it's a project name
        if [[ "$1" != -* ]]; then
            cmd_list "$1"
        else
            echo "Unknown command: $1"
            cmd_help
            exit 1
        fi
        ;;
esac
