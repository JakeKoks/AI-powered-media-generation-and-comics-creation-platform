// Simple database connection test
const { Pool } = require('pg');

// Try different connection approaches
const configs = [
  'postgresql://postgres:postgres123@localhost:5432/aicomics',
  'postgresql://postgres:postgres123@127.0.0.1:5432/aicomics',
  {
    host: 'localhost',
    port: 5432,
    database: 'aicomics',
    user: 'postgres',
    password: 'postgres123'
  },
  {
    host: '127.0.0.1',
    port: 5432,
    database: 'aicomics',
    user: 'postgres',
    password: 'postgres123'
  }
];

async function testConnection(config, index) {
  const pool = new Pool(typeof config === 'string' ? { connectionString: config } : config);
  
  try {
    console.log(`\n🧪 Test ${index + 1}:`, typeof config === 'string' ? config : JSON.stringify(config));
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('✅ Connected successfully!');
    console.log('Time:', result.rows[0].now);
    client.release();
    return true;
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
    return false;
  } finally {
    await pool.end();
  }
}

async function runTests() {
  for (let i = 0; i < configs.length; i++) {
    const success = await testConnection(configs[i], i);
    if (success) {
      console.log('\n🎉 Found working configuration!');
      break;
    }
  }
}

runTests();
