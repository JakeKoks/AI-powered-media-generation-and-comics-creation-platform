// Test different connection methods to understand pg_hba.conf behavior
const { Pool } = require('pg');

const tests = [
  {
    name: "127.0.0.1 with password",
    config: { connectionString: 'postgresql://postgres:postgres123@127.0.0.1:5432/aicomics' }
  },
  {
    name: "127.0.0.1 without password (trust)",
    config: { connectionString: 'postgresql://postgres@127.0.0.1:5432/aicomics' }
  },
  {
    name: "localhost with password", 
    config: { connectionString: 'postgresql://postgres:postgres123@localhost:5432/aicomics' }
  },
  {
    name: "Individual config 127.0.0.1",
    config: {
      host: '127.0.0.1',
      port: 5432,
      database: 'aicomics',
      user: 'postgres',
      password: 'postgres123'
    }
  },
  {
    name: "Individual config 127.0.0.1 no password",
    config: {
      host: '127.0.0.1',
      port: 5432,
      database: 'aicomics',
      user: 'postgres'
      // no password - testing trust
    }
  }
];

async function testConnection(test) {
  const pool = new Pool(test.config);
  
  try {
    console.log(`\n🧪 Testing: ${test.name}`);
    console.log(`Config:`, typeof test.config.connectionString !== 'undefined' ? 
      test.config.connectionString.replace(/:[^:@]+@/, ':***@') : 
      {...test.config, password: test.config.password ? '***' : 'none'});
    
    const client = await pool.connect();
    const result = await client.query('SELECT NOW(), current_user');
    console.log('✅ SUCCESS!');
    console.log(`   Connected as: ${result.rows[0].current_user}`);
    console.log(`   Time: ${result.rows[0].now}`);
    client.release();
    return true;
  } catch (err) {
    console.log('❌ FAILED:', err.message);
    console.log(`   Error code: ${err.code}`);
    return false;
  } finally {
    await pool.end();
  }
}

async function runAllTests() {
  console.log('🔍 Testing PostgreSQL Authentication Methods\n');
  console.log('Based on pg_hba.conf analysis:');
  console.log('- 127.0.0.1/32 should use TRUST (no password)');
  console.log('- Other connections use SCRAM-SHA-256 (encrypted password)\n');
  
  for (const test of tests) {
    const success = await testConnection(test);
    if (success) {
      console.log('\n🎉 Found working configuration! Use this one.\n');
      break;
    }
  }
}

runAllTests();
