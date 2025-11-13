# Kanboard API Scripts

Scripts for interacting with Kanboard project management system via API.

## Scripts

### kanboard-api.sh
Bash wrapper for Kanboard API calls.

**Usage:**
```bash
./scripts/kanboard/kanboard-api.sh <method> [params]
```

**Example:**
```bash
./scripts/kanboard/kanboard-api.sh getMyProjects
```

### kanboard-api.mjs / kanboard-api.ts
Modern JavaScript/TypeScript implementations of Kanboard API client.

**Usage:**
```bash
# Using .mjs (JavaScript)
node ./scripts/kanboard/kanboard-api.mjs <method> [params]

# Using .ts (TypeScript)
deno run ./scripts/kanboard/kanboard-api.ts <method> [params]
```

### kb-create-project.mjs
Creates a new project in Kanboard.

**Usage:**
```bash
node ./scripts/kanboard/kb-create-project.mjs <project-name> [description]
```

**Example:**
```bash
node ./scripts/kanboard/kb-create-project.mjs "New Website" "Company website redesign"
```

### kb-create-task.mjs
Creates a new task in a Kanboard project.

**Usage:**
```bash
node ./scripts/kanboard/kb-create-task.mjs <project-id> <task-title> [description]
```

**Example:**
```bash
node ./scripts/kanboard/kb-create-task.mjs 1 "Setup database" "Configure PostgreSQL"
```

## Configuration

API credentials should be configured via environment variables:
- `KANBOARD_URL` - Your Kanboard instance URL
- `KANBOARD_API_KEY` - Your API key/token

Or in a configuration file (implementation-specific).

## API Documentation

For available API methods and parameters, see:
- [Kanboard API Documentation](https://docs.kanboard.org/en/latest/api/)
