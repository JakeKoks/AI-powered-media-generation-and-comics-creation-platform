#!/usr/bin/env node

/**
 * Setup validation script for AI Media & Comics Website
 * Tests basic configuration and dependencies
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 AI Media & Comics Website - Setup Validation');
console.log('================================================\n');

// Test 1: Check required files exist
console.log('📁 Checking project structure...');
const requiredFiles = [
  'package.json',
  'docker-compose.yml',
  'Makefile',
  '.env.example',
  'tsconfig.json',
  '.eslintrc.js',
  '.prettierrc',
  'README.md'
];

const requiredDirs = [
  'apps',
  'packages',
  'infrastructure',
  'docs',
  'tests',
  'scripts'
];

let allFilesExist = true;
let allDirsExist = true;

requiredFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file} - MISSING`);
    allFilesExist = false;
  }
});

requiredDirs.forEach(dir => {
  if (fs.existsSync(dir)) {
    console.log(`✅ ${dir}/`);
  } else {
    console.log(`❌ ${dir}/ - MISSING`);
    allDirsExist = false;
  }
});

console.log('');

// Test 2: Check package.json configuration
console.log('📦 Checking package.json configuration...');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  const requiredScripts = ['dev', 'build', 'test', 'lint', 'format'];
  requiredScripts.forEach(script => {
    if (packageJson.scripts && packageJson.scripts[script]) {
      console.log(`✅ Script: ${script}`);
    } else {
      console.log(`❌ Script: ${script} - MISSING`);
    }
  });
  
  if (packageJson.workspaces) {
    console.log('✅ Workspaces configured');
  } else {
    console.log('❌ Workspaces - NOT CONFIGURED');
  }
} catch (error) {
  console.log('❌ package.json - INVALID JSON');
}

console.log('');

// Test 3: Check Docker configuration
console.log('🐳 Checking Docker configuration...');
try {
  const dockerCompose = fs.readFileSync('docker-compose.yml', 'utf8');
  
  const requiredServices = ['postgres', 'redis', 'minio', 'backend', 'frontend', 'ai-worker'];
  requiredServices.forEach(service => {
    if (dockerCompose.includes(service + ':')) {
      console.log(`✅ Service: ${service}`);
    } else {
      console.log(`❌ Service: ${service} - MISSING`);
    }
  });
} catch (error) {
  console.log('❌ docker-compose.yml - NOT READABLE');
}

console.log('');

// Test 4: Check environment template
console.log('🔧 Checking environment configuration...');
try {
  const envExample = fs.readFileSync('.env.example', 'utf8');
  
  const requiredEnvVars = [
    'DATABASE_URL',
    'REDIS_URL', 
    'JWT_SECRET',
    'MINIO_ENDPOINT'
  ];
  
  requiredEnvVars.forEach(envVar => {
    if (envExample.includes(envVar + '=')) {
      console.log(`✅ ${envVar}`);
    } else {
      console.log(`❌ ${envVar} - MISSING`);
    }
  });
} catch (error) {
  console.log('❌ .env.example - NOT READABLE');
}

console.log('');

// Test 5: Git repository status
console.log('📝 Checking Git repository...');
if (fs.existsSync('.git')) {
  console.log('✅ Git repository initialized');
  
  if (fs.existsSync('.gitignore')) {
    console.log('✅ .gitignore exists');
  } else {
    console.log('❌ .gitignore - MISSING');
  }
} else {
  console.log('❌ Git repository - NOT INITIALIZED');
}

console.log('');

// Summary
console.log('📊 Validation Summary');
console.log('====================');

if (allFilesExist && allDirsExist) {
  console.log('✅ Project structure: COMPLETE');
} else {
  console.log('❌ Project structure: INCOMPLETE');
}

console.log('');
console.log('🎯 Next Steps:');
console.log('1. Copy .env.example to .env and update values');
console.log('2. Run: docker-compose up -d (start services)');
console.log('3. Create backend and frontend applications');
console.log('4. Setup database schema with Prisma');
console.log('5. Implement authentication system');
console.log('');
console.log('🚀 Ready for Phase 1: Database & Authentication!');
