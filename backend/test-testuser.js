// Test with the new test user
const { Client } = require('pg');

console.log('🧪 Testing with Test User');
console.log('========================');

async function testWithTestUser() {
  console.log('\n🔍 Test: Test user authentication');
  const client = new Client({
    connectionString: 'postgresql://testuser:testpass123@127.0.0.1:5432/aicomics'
  });

  try {
    console.log('🔌 Connecting with test user...');
    await client.connect();
    console.log('✅ SUCCESS: Connected with test user!');
    
    const result = await client.query('SELECT NOW() as current_time, current_user');
    console.log('📊 Connection details:', {
      currentTime: result.rows[0].current_time,
      user: result.rows[0].current_user
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

testWithTestUser();
