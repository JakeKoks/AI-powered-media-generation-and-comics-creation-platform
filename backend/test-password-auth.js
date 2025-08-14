// Test proper password authentication
const { Client } = require('pg');

console.log('🧪 Testing Password Authentication');
console.log('=================================');

async function testPasswordAuth() {
  console.log('\n🔍 Test: Standard password authentication');
  const client = new Client({
    connectionString: 'postgresql://postgres:postgres123@127.0.0.1:5432/aicomics'
  });

  try {
    console.log('🔌 Connecting with password authentication...');
    await client.connect();
    console.log('✅ SUCCESS: Connected with password authentication!');
    
    const result = await client.query('SELECT NOW() as current_time, current_user, version()');
    console.log('📊 Connection details:', {
      currentTime: result.rows[0].current_time,
      user: result.rows[0].current_user,
      version: result.rows[0].version.split(' ')[0] + ' ' + result.rows[0].version.split(' ')[1]
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

testPasswordAuth().then(success => {
  if (success) {
    console.log('\n🎉 SUCCESS: Password authentication is working!');
    console.log('🚀 Ready to start the backend server!');
  } else {
    console.log('\n❌ Password authentication failed');
  }
  process.exit(success ? 0 : 1);
});
