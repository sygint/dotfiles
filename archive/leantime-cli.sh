#!/usr/bin/env bash
# Leantime CLI - Manage projects and tickets via JSON-RPC API
# Based on Leantime JSON-RPC v2.0 API
#
# Usage:
#   leantime-cli init              # Interactive setup to configure API credentials
#   leantime-cli projects          # List all projects
#   leantime-cli use <project_id>  # Set default project
#   leantime-cli tickets           # List tickets in default project
#   leantime-cli add "<headline>"  # Create a ticket in default project
#
# Environment variables:
#   LEANTIME_URL       - Your Leantime instance URL (e.g., https://leantime.example.com)
#   LEANTIME_API_KEY   - Your API key generated from Company Settings

set -euo pipefail

# Configuration
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/leantime/config"
DEFAULT_PROJECT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/leantime/default-project"
LOCAL_PROJECT_FILE=".leantime"
VERSION="2.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Global project override (set via -p flag)
PROJECT_OVERRIDE=""

# Get project ID with priority: flag > local file > global default
get_project() {
    # 1. Explicit flag override
    if [[ -n "$PROJECT_OVERRIDE" ]]; then
        echo "$PROJECT_OVERRIDE"
        return
    fi
    
    # 2. Local .leantime file in current directory
    if [[ -f "$LOCAL_PROJECT_FILE" ]]; then
        local project_id
        project_id=$(cat "$LOCAL_PROJECT_FILE" | tr -d '[:space:]')
        if [[ -n "$project_id" ]]; then
            echo "$project_id"
            return
        fi
    fi
    
    # 3. Global default
    if [[ -f "$DEFAULT_PROJECT_FILE" ]]; then
        local project_id
        project_id=$(cat "$DEFAULT_PROJECT_FILE" | tr -d '[:space:]')
        if [[ -n "$project_id" ]]; then
            echo "$project_id"
            return
        fi
    fi
    
    echo ""
}

# Set default project
cmd_use() {
    local project_id="${1:-}"
    local scope="${2:-local}"
    
    if [[ -z "$project_id" ]]; then
        echo "Usage: leantime-cli use <project_id> [--global]"
        echo ""
        echo "Sets the default project for commands."
        echo "  (no flag)  Save to .leantime in current directory"
        echo "  --global   Save to ~/.config/leantime/default-project"
        exit 1
    fi
    
    # Check for --global flag
    if [[ "$scope" == "--global" || "$scope" == "-g" ]]; then
        mkdir -p "$(dirname "$DEFAULT_PROJECT_FILE")"
        echo "$project_id" > "$DEFAULT_PROJECT_FILE"
        log_success "Set global default project: $project_id"
    else
        echo "$project_id" > "$LOCAL_PROJECT_FILE"
        log_success "Set local project (.leantime): $project_id"
    fi
}

# Show which project is active
cmd_which() {
    echo -e "${BLUE}Project Resolution:${NC}"
    
    if [[ -n "$PROJECT_OVERRIDE" ]]; then
        echo -e "  ${GREEN}→${NC} Flag override: $PROJECT_OVERRIDE"
    fi
    
    if [[ -f "$LOCAL_PROJECT_FILE" ]]; then
        local id=$(cat "$LOCAL_PROJECT_FILE" | tr -d '[:space:]')
        echo -e "  ${GREEN}→${NC} Local (.leantime): $id"
    else
        echo -e "  ${DIM}  Local (.leantime): not set${NC}"
    fi
    
    if [[ -f "$DEFAULT_PROJECT_FILE" ]]; then
        local id=$(cat "$DEFAULT_PROJECT_FILE" | tr -d '[:space:]')
        echo -e "  ${DIM}  Global default: $id${NC}"
    else
        echo -e "  ${DIM}  Global default: not set${NC}"
    fi
    
    local active
    active=$(get_project)
    if [[ -n "$active" ]]; then
        # Get project name
        local response
        response=$(api_call "leantime.rpc.projects.getProject" "{\"id\": \"$active\"}")
        local name
        name=$(echo "$response" | jq -r '.result.name // "unknown"')
        echo ""
        echo -e "${BLUE}Active:${NC} $name ${DIM}(ID: $active)${NC}"
    else
        echo ""
        echo -e "${YELLOW}No project selected. Use 'leantime-cli use <project_id>'${NC}"
    fi
}

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
    
    # Override with environment variables if set
    LEANTIME_URL="${LEANTIME_URL:-${LEANTIME_URL_CONFIG:-}}"
    LEANTIME_API_KEY="${LEANTIME_API_KEY:-${LEANTIME_API_KEY_CONFIG:-}}"
    
    if [[ -z "$LEANTIME_URL" ]] || [[ -z "$LEANTIME_API_KEY" ]]; then
        return 1
    fi
    
    return 0
}

# Save configuration
save_config() {
    local url="$1"
    local api_key="$2"
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOF
# Leantime CLI Configuration
LEANTIME_URL_CONFIG="$url"
LEANTIME_API_KEY_CONFIG="$api_key"
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_success "Configuration saved to $CONFIG_FILE"
}

# Make JSON-RPC API call
api_call() {
    local method="$1"
    local params="${2:-{}}"
    local request_id="${3:-1}"
    
    if ! load_config; then
        log_error "Configuration not found. Run 'leantime-cli.sh init' first."
        exit 1
    fi
    
    local payload
    payload=$(jq -n \
        --arg method "$method" \
        --argjson params "$params" \
        --arg id "$request_id" \
        '{
            jsonrpc: "2.0",
            method: $method,
            params: $params,
            id: $id
        }')
    
    local response
    response=$(curl -s -X POST "$LEANTIME_URL/api/jsonrpc" \
        -H "x-api-key: $LEANTIME_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    # Check for errors in response
    if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
        local error_message
        error_message=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        log_error "API Error: $error_message"
        return 1
    fi
    
    echo "$response"
}

# Initialize configuration
cmd_init() {
    log_info "Leantime CLI Configuration"
    echo ""
    
    # Get Leantime URL
    read -r -p "Enter your Leantime URL (e.g., https://leantime.example.com): " url
    url="${url%/}"  # Remove trailing slash
    
    # Get API Key
    echo ""
    log_info "To generate an API key:"
    log_info "1. Log into your Leantime instance"
    log_info "2. Go to Company Settings (⚙️ icon)"
    log_info "3. Navigate to the 'API Keys' section"
    log_info "4. Click 'Create New API Key'"
    log_info "5. Copy the secret key (you'll only see it once!)"
    echo ""
    read -r -p "Enter your API key: " api_key
    
    # Save configuration
    save_config "$url" "$api_key"
    
    # Test connection
    log_info "Testing connection..."
    if api_call "leantime.rpc.projects.getAll" '{}' > /dev/null 2>&1; then
        log_success "Connection successful! Configuration complete."
    else
        log_warning "Connection test failed. Please verify your URL and API key."
    fi
}

# List all projects
cmd_projects() {
    log_info "Fetching projects..."
    
    local response
    response=$(api_call "leantime.rpc.projects.getAll" '{}')
    
    if [[ -z "$response" ]]; then
        log_error "Failed to fetch projects"
        return 1
    fi
    
    echo ""
    printf "%-6s %-40s %-20s\n" "ID" "NAME" "CLIENT"
    printf "%-6s %-40s %-20s\n" "---" "----" "------"
    echo "$response" | jq -r '.result[] | "\(.id)\t\(.name)\t\(.clientName // "No Client")"' | \
        awk -F'\t' '{printf "%-6s %-40s %-20s\n", $1, $2, $3}'
}

# Get project by ID
cmd_project_get() {
    local project_id="$1"
    
    local response
    response=$(api_call "leantime.rpc.projects.getProject" "{\"id\": \"$project_id\"}")
    
    echo "$response" | jq -r '.result'
}

# Create a new project
cmd_create_project() {
    local name="$1"
    local description="${2:-}"
    local client_id="${3:-0}"
    
    if [[ -z "$name" ]]; then
        echo "Usage: leantime-cli create-project \"<name>\" [description] [client_id]"
        exit 1
    fi
    
    log_info "Creating project: $name"
    
    local params
    params=$(jq -n \
        --arg name "$name" \
        --arg details "$description" \
        --arg clientId "$client_id" \
        '{
            name: $name,
            details: $details,
            clientId: ($clientId | tonumber),
            hourBudget: 0,
            dollarBudget: 0,
            psettings: "restricted"
        }')
    
    local response
    response=$(api_call "leantime.rpc.projects.addProject" "$params")
    
    if [[ -z "$response" ]]; then
        log_error "Failed to create project"
        return 1
    fi
    
    local project_id
    project_id=$(echo "$response" | jq -r '.result')
    
    if [[ "$project_id" != "null" ]] && [[ -n "$project_id" ]]; then
        log_success "Project created with ID: $project_id"
        echo "$project_id"
    else
        log_error "Failed to create project"
        return 1
    fi
}

# List tickets in a project
cmd_tickets() {
    local project_id="${1:-}"
    
    # Try to get project from context if not provided
    if [[ -z "$project_id" ]]; then
        project_id=$(get_project)
        if [[ -z "$project_id" ]]; then
            log_error "No project specified. Use -p <project_id> or set a default with 'leantime-cli use <project_id>'"
            exit 1
        fi
    fi
    
    log_info "Fetching tickets for project $project_id..."
    
    local params
    params=$(jq -n \
        --arg projectId "$project_id" \
        '{
            projectId: ($projectId | tonumber)
        }')
    
    local response
    response=$(api_call "leantime.rpc.tickets.getAllBySearchCriteria" "$params")
    
    if [[ -z "$response" ]]; then
        log_error "Failed to fetch tickets"
        return 1
    fi
    
    echo ""
    printf "%-6s %-50s %-15s %-10s\n" "ID" "HEADLINE" "STATUS" "TYPE"
    printf "%-6s %-50s %-15s %-10s\n" "---" "--------" "------" "----"
    echo "$response" | jq -r '.result[] | "\(.id)\t\(.headline)\t\(.status)\t\(.type)"' | \
        awk -F'\t' '{printf "%-6s %-50s %-15s %-10s\n", $1, $2, $3, $4}'
}

# Get a specific ticket
cmd_ticket_get() {
    local ticket_id="$1"
    
    local response
    response=$(api_call "leantime.rpc.tickets.getTicket" "{\"id\": \"$ticket_id\"}")
    
    echo "$response" | jq -r '.result'
}

# Add a ticket/task with options parsing
cmd_add() {
    local project_id=""
    local headline=""
    local description=""
    local type="task"
    local status="3"  # 3 = Not started
    local priority=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--project)
                project_id="$2"
                shift 2
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -t|--type)
                type="$2"
                shift 2
                ;;
            -s|--status)
                status="$2"
                shift 2
                ;;
            --priority)
                priority="$2"
                shift 2
                ;;
            *)
                if [[ -z "$headline" ]]; then
                    headline="$1"
                    shift
                else
                    shift
                fi
                ;;
        esac
    done
    
    # Get project from context if not specified
    if [[ -z "$project_id" ]]; then
        project_id=$(get_project)
        if [[ -z "$project_id" ]]; then
            log_error "No project specified. Use -p <project_id> or set a default with 'leantime-cli use <project_id>'"
            exit 1
        fi
    fi
    
    if [[ -z "$headline" ]]; then
        log_error "Headline is required"
        echo "Usage: leantime-cli add \"<headline>\" [options]"
        echo "Options:"
        echo "  -p, --project <id>     Project ID (uses default if not specified)"
        echo "  -d, --description <text>  Ticket description"
        echo "  -t, --type <type>      Type: task, bug, feature (default: task)"
        echo "  -s, --status <status>  Status number (default: 3 = Not started)"
        echo "  --priority <priority>  Priority level"
        exit 1
    fi
    
    log_info "Creating ticket: $headline"
    
    local params
    params=$(jq -n \
        --arg projectId "$project_id" \
        --arg headline "$headline" \
        --arg description "$description" \
        --arg type "$type" \
        --arg status "$status" \
        '{
            projectId: ($projectId | tonumber),
            headline: $headline,
            description: $description,
            type: $type,
            status: ($status | tonumber)
        }')
    
    local response
    response=$(api_call "leantime.rpc.tickets.addTicket" "$params")
    
    if [[ -z "$response" ]]; then
        log_error "Failed to create ticket"
        return 1
    fi
    
    local ticket_id
    ticket_id=$(echo "$response" | jq -r '.result')
    
    if [[ "$ticket_id" != "null" ]] && [[ -n "$ticket_id" ]]; then
        log_success "Ticket created with ID: $ticket_id"
        echo "$ticket_id"
    else
        log_error "Failed to create ticket"
        return 1
    fi
}

# Quick add ticket (simpler API)
cmd_ticket_quick_add() {
    local project_id="$1"
    local headline="$2"
    local type="${3:-task}"
    
    log_info "Quick adding ticket: $headline"
    
    local params
    params=$(jq -n \
        --arg projectId "$project_id" \
        --arg headline "$headline" \
        --arg type "$type" \
        '{
            projectId: ($projectId | tonumber),
            headline: $headline,
            type: $type
        }')
    
    local response
    response=$(api_call "leantime.rpc.tickets.quickAddTicket" "$params")
    
    if [[ -z "$response" ]]; then
        log_error "Failed to create ticket"
        return 1
    fi
    
    local ticket_id
    ticket_id=$(echo "$response" | jq -r '.result')
    
    if [[ "$ticket_id" != "null" ]] && [[ -n "$ticket_id" ]]; then
        log_success "Ticket created with ID: $ticket_id"
        echo "$ticket_id"
    else
        log_error "Failed to create ticket"
        return 1
    fi
}

# Add a milestone
cmd_milestone_add() {
    local project_id="$1"
    local headline="$2"
    local start_date="${3:-}"
    local end_date="${4:-}"
    local tags="${5:-}"
    
    log_info "Creating milestone: $headline"
    
    local params
    params=$(jq -n \
        --arg projectId "$project_id" \
        --arg headline "$headline" \
        --arg editFrom "$start_date" \
        --arg editTo "$end_date" \
        --arg tags "$tags" \
        '{
            projectId: ($projectId | tonumber),
            headline: $headline,
            editFrom: $editFrom,
            editTo: $editTo,
            tags: $tags
        }')
    
    local response
    response=$(api_call "leantime.rpc.tickets.quickAddMilestone" "$params")
    
    if [[ -z "$response" ]]; then
        log_error "Failed to create milestone"
        return 1
    fi
    
    local milestone_id
    milestone_id=$(echo "$response" | jq -r '.result')
    
    if [[ "$milestone_id" != "null" ]] && [[ -n "$milestone_id" ]]; then
        log_success "Milestone created with ID: $milestone_id"
        echo "$milestone_id"
    else
        log_error "Failed to create milestone"
        return 1
    fi
}

# Quick status overview
cmd_status() {
    log_info "Fetching project overview..."
    
    local response
    response=$(api_call "leantime.rpc.projects.getAll" '{}')
    
    if [[ -z "$response" ]]; then
        log_error "Failed to fetch projects"
        return 1
    fi
    
    local active_project
    active_project=$(get_project)
    
    echo ""
    echo -e "${BLUE}═══ Leantime Status ═══${NC}"
    echo ""
    
    # Show projects
    local project_count
    project_count=$(echo "$response" | jq -r '.result | length')
    echo -e "${BLUE}Projects:${NC} $project_count total"
    echo ""
    
    # Show active project if set
    if [[ -n "$active_project" ]]; then
        local project_info
        project_info=$(api_call "leantime.rpc.projects.getProject" "{\"id\": \"$active_project\"}")
        local project_name
        project_name=$(echo "$project_info" | jq -r '.result.name // "Unknown"')
        
        echo -e "${GREEN}→ Active Project:${NC} $project_name (ID: $active_project)"
        
        # Get ticket count for active project
        local tickets_params
        tickets_params=$(jq -n --arg projectId "$active_project" '{projectId: ($projectId | tonumber)}')
        local tickets_response
        tickets_response=$(api_call "leantime.rpc.tickets.getAllBySearchCriteria" "$tickets_params")
        local ticket_count
        ticket_count=$(echo "$tickets_response" | jq -r '.result | length')
        
        echo -e "  ${DIM}Tickets: $ticket_count${NC}"
    else
        echo -e "${YELLOW}No active project set${NC}"
        echo -e "${DIM}Use 'leantime-cli use <project_id>' to set one${NC}"
    fi
    
    echo ""
}

# Display usage
cmd_help() {
    cat << EOF
${YELLOW}Leantime CLI - Version $VERSION${NC}

${YELLOW}Usage:${NC} leantime-cli [-p project_id] <command> [args]

${YELLOW}Global Options:${NC}
  -p, --project <id>              Use specific project (overrides defaults)

${YELLOW}Commands:${NC}
  init                            Login and configure Leantime CLI
  use <project_id> [--global]     Set default project (local .leantime or global)
  which                           Show active project resolution
  projects                        List all projects
  create-project "<name>" [desc]  Create a new project
  tickets [project_id]            List tickets (uses default if no id)
  add "<headline>" [opts]         Add a new ticket
  status                          Quick overview of projects and tickets

${YELLOW}Add Options:${NC}
  -p, --project <id>              Project ID (uses default if not specified)
  -d, --description <text>        Ticket description
  -t, --type <type>               Type: task, bug, feature (default: task)
  -s, --status <num>              Status number (default: 3 = Not started)
  --priority <priority>           Priority level

${YELLOW}Examples:${NC}
  leantime-cli init                           # Initial setup
  leantime-cli create-project "NixOS Config"  # Create project
  leantime-cli use 5                          # Set local default
  leantime-cli use 5 --global                 # Set global default
  leantime-cli tickets                        # Uses default project
  leantime-cli add "Fix bug" -t bug           # Add to default project
  leantime-cli -p 5 tickets                   # Override for one command

${YELLOW}Project Resolution (priority):${NC}
  1. -p/--project flag
  2. .leantime file in current directory
  3. ~/.config/leantime/default-project

${YELLOW}Environment:${NC}
  LEANTIME_URL       API base URL (default: from config)
  LEANTIME_API_KEY   API key (default: from config)

${YELLOW}Legacy Commands (still supported):${NC}
  project list|get|create         Old-style project commands
  ticket list|get|add             Old-style ticket commands
  milestone add                   Add a milestone

${YELLOW}Configuration:${NC}
  Config file: $CONFIG_FILE

For more information: https://docs.leantime.io/api/usage
EOF
}

# Display usage
usage() {
    cat << EOF
Leantime CLI - Version $VERSION

USAGE:
    leantime-cli.sh <command> [options]

COMMANDS:
    init                                     Initialize/configure Leantime CLI
    
    project list                             List all projects
    project get <project_id>                 Get project details
    project create <name> [description] [client_id]
                                            Create a new project
    
    ticket list <project_id>                 List all tickets in a project
    ticket get <ticket_id>                   Get ticket details
    ticket add <project_id> <headline> [description] [type] [status]
                                            Add a new ticket
    ticket quick-add <project_id> <headline> [type]
                                            Quick add a ticket
    
    milestone add <project_id> <headline> [start_date] [end_date] [tags]
                                            Add a milestone

EXAMPLES:
    # Initial setup
    leantime-cli.sh init

    # Create a project
    leantime-cli.sh project create "NixOS Configuration" "My NixOS homelab setup"

    # List projects
    leantime-cli.sh project list

    # Add tickets to a project (project_id = 5)
    leantime-cli.sh ticket add 5 "Setup flake configuration" "Create initial flake.nix structure"
    leantime-cli.sh ticket quick-add 5 "Configure home-manager"

    # Create a milestone
    leantime-cli.sh milestone add 5 "Phase 1: Base Setup" "2025-01-01" "2025-02-01" "#project"

    # List tickets
    leantime-cli.sh ticket list 5

ENVIRONMENT VARIABLES:
    LEANTIME_URL       Your Leantime instance URL
    LEANTIME_API_KEY   Your API key from Leantime

CONFIGURATION:
    Configuration is stored in: $CONFIG_FILE

For more information, visit: https://docs.leantime.io/api/usage
EOF
}

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        cmd_help
        exit 0
    fi
    
    # Parse global flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--project)
                PROJECT_OVERRIDE="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    local command="$1"
    shift
    
    case "$command" in
        init)
            cmd_init
            ;;
        use)
            cmd_use "$@"
            ;;
        which)
            cmd_which
            ;;
        projects)
            cmd_projects
            ;;
        create-project)
            cmd_create_project "$@"
            ;;
        tickets)
            cmd_tickets "$@"
            ;;
        add)
            cmd_add "$@"
            ;;
        status)
            cmd_status
            ;;
        # Legacy commands for backwards compatibility
        project)
            if [[ $# -eq 0 ]]; then
                log_error "Project command requires a subcommand"
                cmd_help
                exit 1
            fi
            local subcommand="$1"
            shift
            case "$subcommand" in
                list)
                    cmd_projects
                    ;;
                get)
                    if [[ $# -lt 1 ]]; then
                        log_error "project get requires a project ID"
                        exit 1
                    fi
                    cmd_project_get "$1"
                    ;;
                create)
                    if [[ $# -lt 1 ]]; then
                        log_error "project create requires a project name"
                        exit 1
                    fi
                    cmd_create_project "$@"
                    ;;
                *)
                    log_error "Unknown project subcommand: $subcommand"
                    cmd_help
                    exit 1
                    ;;
            esac
            ;;
        ticket)
            if [[ $# -eq 0 ]]; then
                log_error "Ticket command requires a subcommand"
                cmd_help
                exit 1
            fi
            local subcommand="$1"
            shift
            case "$subcommand" in
                list)
                    cmd_tickets "$@"
                    ;;
                get)
                    if [[ $# -lt 1 ]]; then
                        log_error "ticket get requires a ticket ID"
                        exit 1
                    fi
                    cmd_ticket_get "$1"
                    ;;
                add)
                    if [[ $# -lt 2 ]]; then
                        log_error "ticket add requires project ID and headline"
                        exit 1
                    fi
                    # Old style: project_id headline description type status
                    local old_project_id="$1"
                    local old_headline="$2"
                    local old_description="${3:-}"
                    shift 2
                    [[ $# -gt 0 ]] && shift
                    cmd_add "$old_headline" -p "$old_project_id" -d "$old_description" "$@"
                    ;;
                quick-add)
                    if [[ $# -lt 2 ]]; then
                        log_error "ticket quick-add requires project ID and headline"
                        exit 1
                    fi
                    cmd_ticket_quick_add "$@"
                    ;;
                *)
                    log_error "Unknown ticket subcommand: $subcommand"
                    cmd_help
                    exit 1
                    ;;
            esac
            ;;
        milestone)
            if [[ $# -eq 0 ]]; then
                log_error "Milestone command requires a subcommand"
                cmd_help
                exit 1
            fi
            local subcommand="$1"
            shift
            case "$subcommand" in
                add)
                    if [[ $# -lt 2 ]]; then
                        log_error "milestone add requires project ID and headline"
                        exit 1
                    fi
                    cmd_milestone_add "$@"
                    ;;
                *)
                    log_error "Unknown milestone subcommand: $subcommand"
                    cmd_help
                    exit 1
                    ;;
            esac
            ;;
        -h|--help|help)
            cmd_help
            ;;
        -v|--version)
            echo "Leantime CLI version $VERSION"
            ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for dep in curl jq; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them before using this script"
        exit 1
    fi
}

# Run the script
check_dependencies
main "$@"
