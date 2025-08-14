// Test Unix domain socket connection (the correct approach!)
const { Client } = require('pg');

console.log('🧪 Testing Unix Domain Socket Connection');
console.log('=======================================');

async function testUnixSocket() {
  console.log('\n🔍 Test: Unix domain socket (no host specified)');
  const client = new Client({
    // No host = Unix socket connection
    user: 'postgres',
    database: 'aicomics'
    // No password, no port
  });

  try {
    console.log('🔌 Connecting via Unix domain socket...');
    await client.connect();
    console.log('✅ SUCCESS: Connected via Unix socket with trust authentication!');
    
    const result = await client.query('SELECT NOW() as current_time, current_user, inet_server_addr() as server_addr');
    console.log('📊 Connection details:', {
      currentTime: result.rows[0].current_time,
      user: result.rows[0].current_user,
      serverAddr: result.rows[0].server_addr || 'Unix socket (no IP)'
    });
    
    await client.end();
    console.log('🔚 Connection closed successfully');
    return true;
  } catch (error) {
    console.log('❌ FAILED:', error.message);
    console.log('🔍 Error code:', error.code);
    return false;
  }
}

async function testExplicitSocketPath() {
  console.log('\n🔍 Test: Explicit Unix socket path');
  const client = new Client({
    host: '/var/run/postgresql', // socket directory
    user: 'postgres',
    database: 'aicomics'
    // No password
  });

  try {
    console.log('🔌 Connecting via explicit socket path...');
    await client.connect();
    console.log('✅ SUCCESS: Connected via explicit socket path!');
    await client.end();
    return true;
  } catch (error) {
    console.log('❌ FAILED:', error.message);
    return false;
  }
}

async function runTests() {
  const success1 = await testUnixSocket();
  const success2 = await testExplicitSocketPath();
  
  if (success1 || success2) {
    console.log('\n🎉 SUCCESS: Unix socket connection works!');
    console.log('🔧 We need to update our database config to use Unix sockets');
  } else {
    console.log('\n❌ Both Unix socket methods failed');
  }
}

runTests();
