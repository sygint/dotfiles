# Task Tracking System

This directory contains the task tracking system for AI agents and humans.

## Overview
The task tracking system provides a unified interface for both AI agents and human operators to:
- Add new tasks to the work queue
- Track progress of ongoing tasks
- Monitor completion status
- Maintain visibility into agent activities

## Integration with OpenCode
This system integrates with your existing OpenCode setup through:
- The TaskSync V4 protocol that prevents automatic session termination
- LM Studio model access via OpenAI-compatible API at http://localhost:1234/v1
- Standardized task logging that can be monitored by humans

## Usage Examples

### Adding Tasks
```bash
# Add a task for AI
./task-tracker.sh add "Implement user authentication" AI high

# Add a task for human
./task-tracker.sh add "Review code changes" Human medium
```

### Managing Tasks
```bash
# List active tasks
./task-tracker.sh list

# Complete a task
./task-tracker.sh complete "task_001"

# Get task status
./task-tracker.sh status "task_001"
```

## Implementation Details

The system uses a simple log-based approach:
- Tasks are logged to `/home/syg/.config/nixos/agents/task-tracking/tasks.log`
- Each entry includes timestamp, task details, priority, and assignment
- The system supports both AI-assigned tasks and human-assigned tasks
- Integration with existing OpenCode workflows through the TaskSync protocol

## Configuration
The task tracking system is designed to work with your existing NixOS configuration:
- Uses standard bash scripting for portability
- Integrates with LM Studio models via OpenAI API compatibility
- Follows the same conventions as your existing OpenCode setup