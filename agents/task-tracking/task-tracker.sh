#!/bin/bash
# Task tracking system for AI agents and humans

# Initialize task tracking
TASK_LOG="/home/syg/.config/nixos/agents/task-tracking/tasks.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create log file if it doesn't exist
touch "$TASK_LOG"

# Function to add a new task
add_task() {
    local task_description="$1"
    local assigned_to="$2"  # "AI" or "Human"
    local priority="${3:-medium}"
    
    # Generate unique task ID
    local task_id="task_$(date +%s%N | tail -c 6)"
    
    echo "[$TIMESTAMP] [TASK] [ID:$task_id] [PRIORITY:$priority] [ASSIGNED:$assigned_to] $task_description" >> "$TASK_LOG"
    echo "Task added: $task_description (ID: $task_id)"
    return 0
}

# Function to complete a task
complete_task() {
    local task_id="$1"
    if grep -q "\[ID:$task_id\]" "$TASK_LOG"; then
        echo "[$TIMESTAMP] [COMPLETED] Task ID: $task_id" >> "$TASK_LOG"
        echo "Task completed: $task_id"
    else
        echo "Task ID not found: $task_id"
        return 1
    fi
}

# Function to list active tasks
list_tasks() {
    echo "Active tasks:"
    grep "^\[.*\] \[TASK\]" "$TASK_LOG" | tail -20
}

# Function to get task status
get_status() {
    local task_id="$1"
    if grep -q "\[ID:$task_id\]" "$TASK_LOG"; then
        echo "[$TIMESTAMP] [STATUS] Task ID: $task_id" >> "$TASK_LOG"
        echo "Status retrieved for: $task_id"
        # Show the task details
        grep "\[ID:$task_id\]" "$TASK_LOG"
    else
        echo "Task ID not found: $task_id"
        return 1
    fi
}

# Function to show recent activity
show_activity() {
    echo "Recent activity:"
    tail -20 "$TASK_LOG"
}

# Main execution
case "$1" in
    add)
        add_task "$2" "$3" "$4"
        ;;
    complete)
        complete_task "$2"
        ;;
    list)
        list_tasks
        ;;
    status)
        get_status "$2"
        ;;
    activity)
        show_activity
        ;;
    *)
        echo "Usage: $0 {add|complete|list|status|activity} [arguments]"
        echo "Examples:"
        echo "  $0 add \"Implement user authentication\" AI high"
        echo "  $0 complete \"task_001\""
        echo "  $0 list"
        echo "  $0 status \"task_001\""
        echo "  $0 activity"
        ;;
esac