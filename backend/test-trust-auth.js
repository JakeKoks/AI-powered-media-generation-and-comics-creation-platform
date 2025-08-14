// Test trust authentication without password
const { Client } = require('pg');

console.log('🧪 Testing Trust Authentication (No Password)');
console.log('===============================================');

async function testTrustAuth() {
  const client = new Client({
    connectionString: 'postgresql://postgres@127.0.0.1:5432/aicomics'
  });

  try {
    console.log('🔌 Connecting to PostgreSQL without password...');
    await client.connect();
    console.log('✅ Connected successfully via trust authentication!');
    
    const result = await client.query('SELECT NOW() as current_time, version() as pg_version');
    console.log('📊 Query result:', {
      currentTime: result.rows[0].current_time,
      version: result.rows[0].pg_version.split(' ')[0] + ' ' + result.rows[0].pg_version.split(' ')[1]
    });
    
    await client.end();
    console.log('🔚 Connection closed successfully');
    return true;
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.error('🔍 Error code:', error.code);
    return false;
  }
}

testTrustAuth().then(success => {
  process.exit(success ? 0 : 1);
});
