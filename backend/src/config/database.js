// Database configuration with professional connection pooling
const { Pool } = require('pg');
require('dotenv').config();

// Create connection pool with proper password authentication
const pool = new Pool({
  // Use standard password authentication over TCP
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres123@127.0.0.1:5432/aicomics',
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return an error after 2 seconds if connection could not be established
});

// Enhanced error handling
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Professional database connection test
const testConnection = async () => {
  try {
    console.log('Testing database connection with connectionString:', 
      process.env.DATABASE_URL || 'postgresql://postgres@127.0.0.1:5432/aicomics');
    
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('✅ Database connected successfully at:', result.rows[0].now);
    client.release();
    return true;
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    return false;
  }
};

// Enhanced query function with error handling
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Query executed', { text, duration, rows: res.rowCount });
    return res;
  } catch (err) {
    console.error('Database query error:', { text, error: err.message });
    throw err;
  }
};

module.exports = {
  pool,
  query,
  testConnection
};
