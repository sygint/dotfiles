#!/usr/bin/env node
/**
 * Kanboard helper - Create project with auto-assignment
 * Usage: kb-create-project.mjs <name> [description]
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env
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
const KANBOARD_URL = env.KANBOARD_URL || 'http://localhost/jsonrpc.php';
const KANBOARD_USER = env.KANBOARD_USER || 'jsonrpc';
const KANBOARD_TOKEN = env.KANBOARD_TOKEN;
const USER_ID = 1; // Your user ID

const args = process.argv.slice(2);
const name = args[0];
const description = args[1] || '';

if (!name) {
  console.error('Usage: kb-create-project.mjs <name> [description]');
  console.error('');
  console.error('Example:');
  console.error('  kb-create-project.mjs "My Project" "Project description"');
  process.exit(1);
}

if (!KANBOARD_TOKEN) {
  console.error('Error: KANBOARD_TOKEN not set in .env');
  process.exit(1);
}

const auth = Buffer.from(`${KANBOARD_USER}:${KANBOARD_TOKEN}`).toString('base64');

async function apiCall(method, params) {
  const response = await fetch(KANBOARD_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${auth}`
    },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: method,
      id: Date.now(),
      params: params
    })
  });
  return await response.json();
}

try {
  // 1. Create project with owner
  console.error('Creating project...');
  const createResult = await apiCall('createProject', {
    name: name,
    description: description,
    owner_id: USER_ID
  });

  if (createResult.error) {
    console.error('Error creating project:', createResult.error.message);
    process.exit(1);
  }

  const projectId = createResult.result;
  console.error(`✓ Project created (ID: ${projectId})`);

  // 2. Add yourself as project member
  console.error('Adding you as project manager...');
  const addUserResult = await apiCall('addProjectUser', {
    project_id: projectId,
    user_id: USER_ID,
    role: 'project-manager'
  });

  if (addUserResult.error) {
    console.error('Warning: Could not add user to project:', addUserResult.error.message);
  } else {
    console.error('✓ Added as project manager');
  }

  // 3. Get project details
  const projectResult = await apiCall('getProjectById', {
    project_id: projectId
  });

  console.log(JSON.stringify(projectResult.result, null, 2));
  console.error('');
  console.error(`🎯 Project "${name}" ready!`);
  console.error(`   Board: ${projectResult.result.url.board}`);
  console.error(`   List:  ${projectResult.result.url.list}`);
} catch (err) {
  console.error('Error:', err.message);
  process.exit(1);
}
