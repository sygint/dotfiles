#!/usr/bin/env node
/**
 * Kanboard API helper script
 * Usage: kanboard-api.mjs <method> [params-as-json]
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables from .env
function loadEnv() {
  const envPath = join(__dirname, '..', '.env');
  try {
    const envContent = readFileSync(envPath, 'utf8');
    const env = {};
    envContent.split('\n').forEach(line => {
      line = line.trim();
      if (line && !line.startsWith('#')) {
        const [key, ...valueParts] = line.split('=');
        const value = valueParts.join('=').replace(/^["']|["']$/g, '');
        env[key] = value;
      }
    });
    return env;
  } catch (err) {
    return {};
  }
}

const env = loadEnv();

// Configuration
const KANBOARD_URL = env.KANBOARD_URL || process.env.KANBOARD_URL || 'http://localhost/jsonrpc.php';
const KANBOARD_USER = env.KANBOARD_USER || process.env.KANBOARD_USER || 'jsonrpc';
const KANBOARD_TOKEN = env.KANBOARD_TOKEN || process.env.KANBOARD_TOKEN;

// Parse command line arguments
const args = process.argv.slice(2);
const method = args[0];
const paramsArg = args[1];

if (!method) {
  console.error('Usage: kanboard-api.mjs <method> [params-as-json]');
  console.error('');
  console.error('Examples:');
  console.error('  kanboard-api.mjs getAllProjects');
  console.error('  kanboard-api.mjs createProject \'{"name":"My Project"}\'');
  console.error('  kanboard-api.mjs createTask \'{"project_id":1,"title":"My Task"}\'');
  console.error('  kanboard-api.mjs getAllTasks \'{"project_id":1,"status_id":1}\'');
  process.exit(1);
}

if (!KANBOARD_TOKEN) {
  console.error('Error: KANBOARD_TOKEN not set');
  console.error('Get your API token from: http://localhost/settings/api');
  console.error('Then add it to .env file or: export KANBOARD_TOKEN="your-token-here"');
  process.exit(1);
}

// Parse params
let params = {};
if (paramsArg) {
  try {
    params = JSON.parse(paramsArg);
  } catch (err) {
    console.error('Error: Invalid JSON in params:', err.message);
    process.exit(1);
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
const auth = Buffer.from(`${KANBOARD_USER}:${KANBOARD_TOKEN}`).toString('base64');

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
    process.exit(1);
  }
} catch (err) {
  console.error('Error:', err.message);
  process.exit(1);
}
