#!/usr/bin/env node
/**
 * Kanboard helper - Create task with auto-assignment
 * Usage: kb-create-task.mjs <project_id> <title> [description] [color]
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
const projectId = parseInt(args[0]);
const title = args[1];
const description = args[2] || '';
const colorId = args[3] || 'blue';

if (!projectId || !title) {
  console.error('Usage: kb-create-task.mjs <project_id> <title> [description] [color]');
  console.error('');
  console.error('Available colors: yellow, blue, green, purple, red, orange, grey, brown,');
  console.error('                 deep_orange, dark_grey, pink, teal, cyan, lime, light_green, amber');
  console.error('');
  console.error('Example:');
  console.error('  kb-create-task.mjs 1 "Fix bug" "Details here" "red"');
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
  // Create task with owner
  console.error(`Creating task in project ${projectId}...`);
  const createResult = await apiCall('createTask', {
    project_id: projectId,
    title: title,
    description: description,
    color_id: colorId,
    owner_id: USER_ID
  });

  if (createResult.error) {
    console.error('Error creating task:', createResult.error.message);
    process.exit(1);
  }

  const taskId = createResult.result;
  if (!taskId) {
    // If owner_id doesn't work on creation, create then update
    console.error('Retrying without owner_id...');
    const retryResult = await apiCall('createTask', {
      project_id: projectId,
      title: title,
      description: description,
      color_id: colorId
    });
    
    if (retryResult.error) {
      console.error('Error creating task:', retryResult.error.message);
      process.exit(1);
    }
    
    const newTaskId = retryResult.result;
    console.error(`✓ Task created (ID: ${newTaskId})`);
    
    // Now assign it
    console.error('Assigning task to you...');
    const updateResult = await apiCall('updateTask', {
      id: newTaskId,
      owner_id: USER_ID
    });
    
    if (updateResult.result) {
      console.error('✓ Task assigned to you');
    }
    
    // Get task details
    const taskResult = await apiCall('getTask', { task_id: newTaskId });
    console.log(JSON.stringify(taskResult.result, null, 2));
    console.error('');
    console.error(`🎯 Task "${title}" created and assigned!`);
    console.error(`   URL: ${taskResult.result.url}`);
  } else {
    console.error(`✓ Task created and assigned (ID: ${taskId})`);
    
    // Get task details
    const taskResult = await apiCall('getTask', { task_id: taskId });
    console.log(JSON.stringify(taskResult.result, null, 2));
    console.error('');
    console.error(`🎯 Task "${title}" created and assigned!`);
    console.error(`   URL: ${taskResult.result.url}`);
  }
} catch (err) {
  console.error('Error:', err.message);
  process.exit(1);
}
