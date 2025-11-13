#!/usr/bin/env -S deno run --allow-net --allow-read
/**
 * Kanboard API helper script (Deno version)
 * Usage: kanboard-api.ts <method> [params-as-json]
 */

// Load environment variables from .env
function loadEnv(): Record<string, string> {
  const envPath = new URL('../.env', import.meta.url).pathname;
  try {
    const envContent = Deno.readTextFileSync(envPath);
    const env: Record<string, string> = {};
    envContent.split('\n').forEach(line => {
      line = line.trim();
      if (line && !line.startsWith('#')) {
        const [key, ...valueParts] = line.split('=');
        const value = valueParts.join('=').replace(/^["']|["']$/g, '');
        env[key] = value;
      }
    });
    return env;
  } catch {
    return {};
  }
}

const env = loadEnv();

// Configuration
const KANBOARD_URL = env.KANBOARD_URL || Deno.env.get('KANBOARD_URL') || 'http://localhost/jsonrpc.php';
const KANBOARD_USER = env.KANBOARD_USER || Deno.env.get('KANBOARD_USER') || 'jsonrpc';
const KANBOARD_TOKEN = env.KANBOARD_TOKEN || Deno.env.get('KANBOARD_TOKEN');

// Parse command line arguments
const args = Deno.args;
const method = args[0];
const paramsArg = args[1];

if (!method) {
  console.error('Usage: kanboard-api.ts <method> [params-as-json]');
  console.error('');
  console.error('Examples:');
  console.error('  kanboard-api.ts getAllProjects');
  console.error('  kanboard-api.ts createProject \'{"name":"My Project"}\'');
  console.error('  kanboard-api.ts createTask \'{"project_id":1,"title":"My Task"}\'');
  console.error('  kanboard-api.ts getAllTasks \'{"project_id":1,"status_id":1}\'');
  Deno.exit(1);
}

if (!KANBOARD_TOKEN) {
  console.error('Error: KANBOARD_TOKEN not set');
  console.error('Get your API token from: http://localhost/settings/api');
  console.error('Then add it to .env file or: export KANBOARD_TOKEN="your-token-here"');
  Deno.exit(1);
}

// Parse params
let params = {};
if (paramsArg) {
  try {
    params = JSON.parse(paramsArg);
  } catch (err) {
    console.error('Error: Invalid JSON in params:', (err as Error).message);
    Deno.exit(1);
  }
}

// Build JSON-RPC request
const request = {
  jsonrpc: '2.0',
  method: method,
  id: Date.now(),
  params: params
};

// Make API call
const auth = btoa(`${KANBOARD_USER}:${KANBOARD_TOKEN}`);

try {
  const response = await fetch(KANBOARD_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${auth}`
    },
    body: JSON.stringify(request)
  });

  const data = await response.json();
  console.log(JSON.stringify(data, null, 2));

  if (data.error) {
    Deno.exit(1);
  }
} catch (err) {
  console.error('Error:', (err as Error).message);
  Deno.exit(1);
}
