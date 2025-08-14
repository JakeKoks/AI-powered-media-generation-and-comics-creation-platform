// Test different connection methods to understand the issue
const { Client } = require('pg');

console.log('🧪 Testing Different Connection Methods');
console.log('=====================================');

// Test 1: Connection string without password to 127.0.0.1
async function test1() {
  console.log('\n🔍 Test 1: Connection string to 127.0.0.1 (no password)');
  const client = new Client({
    connectionString: 'postgresql://postgres@127.0.0.1:5432/aicomics'
  });

  try {
    await client.connect();
    console.log('✅ SUCCESS: Connected via 127.0.0.1');
    await client.end();
  } catch (error) {
    console.log('❌ FAILED:', error.message);
  }
}

// Test 2: Object config to 127.0.0.1
async function test2() {
  console.log('\n🔍 Test 2: Object config to 127.0.0.1 (no password)');
  const client = new Client({
    host: '127.0.0.1',
    port: 5432,
    database: 'aicomics',
    user: 'postgres'
    // No password property
  });

  try {
    await client.connect();
    console.log('✅ SUCCESS: Connected via 127.0.0.1 object config');
    await client.end();
  } catch (error) {
    console.log('❌ FAILED:', error.message);
  }
}

// Test 3: Connection string to localhost
async function test3() {
  console.log('\n🔍 Test 3: Connection string to localhost (no password)');
  const client = new Client({
    connectionString: 'postgresql://postgres@localhost:5432/aicomics'
  });

  try {
    await client.connect();
    console.log('✅ SUCCESS: Connected via localhost');
    await client.end();
  } catch (error) {
    console.log('❌ FAILED:', error.message);
  }
}

// Test 4: Object config to localhost
async function test4() {
  console.log('\n🔍 Test 4: Object config to localhost (no password)');
  const client = new Client({
    host: 'localhost',
    port: 5432,
    database: 'aicomics',
    user: 'postgres'
    // No password property
  });

  try {
    await client.connect();
    console.log('✅ SUCCESS: Connected via localhost object config');
    await client.end();
  } catch (error) {
    console.log('❌ FAILED:', error.message);
  }
}

// Test 5: Try with explicit password as empty string
async function test5() {
  console.log('\n🔍 Test 5: Explicit empty password string');
  const client = new Client({
    host: '127.0.0.1',
    port: 5432,
    database: 'aicomics',
    user: 'postgres',
    password: '' // Explicit empty string
  });

  try {
    await client.connect();
    console.log('✅ SUCCESS: Connected with empty password string');
    await client.end();
  } catch (error) {
    console.log('❌ FAILED:', error.message);
  }
}

async function runAllTests() {
  await test1();
  await test2();
  await test3();
  await test4();
  await test5();
}

runAllTests().then(() => {
  console.log('\n🏁 All tests completed');
});
