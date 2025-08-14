// Professional authentication middleware with JWT
const bcrypt = require('bcryptjs');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const redis = require('redis');

// Redis client for sessions - Use REDIS_URL for Docker networking
const redisUrl = process.env.REDIS_URL || 'redis://redis:6379';
const redisClient = redis.createClient({
  url: redisUrl
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  console.log('✅ Redis connected for sessions:', redisUrl);
});

// Connect to Redis
redisClient.connect().catch(console.error);

// Professional session configuration
const sessionConfig = {
  store: new RedisStore({ client: redisClient }),
  secret: process.env.SESSION_SECRET || 'dev-secret-change-in-production',
  resave: false,
  saveUninitialized: false,
  name: 'aicomics.sid', // Custom session name
  cookie: {
    secure: process.env.NODE_ENV === 'production', // HTTPS only in production
    httpOnly: true, // Prevent XSS
    maxAge: 1000 * 60 * 60 * 24 * 7, // 7 days
    sameSite: 'strict' // CSRF protection
  },
  rolling: true // Reset expiration on activity
};

// Password hashing utilities
const hashPassword = async (password) => {
  const saltRounds = 12; // High security
  return await bcrypt.hash(password, saltRounds);
};

const comparePassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};

// Authentication middleware
const requireAuth = (req, res, next) => {
  if (req.session && req.session.userId) {
    return next();
  } else {
    return res.status(401).json({
      success: false,
      error: 'Authentication required',
      code: 'AUTH_REQUIRED'
    });
  }
};

// Role-based authorization middleware
const requireRole = (minRole = 1) => {
  return (req, res, next) => {
    if (!req.session || !req.session.userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    const userRole = req.session.userRole || 1;
    if (userRole < minRole) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions',
        code: 'INSUFFICIENT_PERMISSIONS',
        required: minRole,
        current: userRole
      });
    }

    return next();
  };
};

// User roles enum
const USER_ROLES = {
  GUEST: 1,
  USER: 2,
  CREATOR: 3,
  ADMIN: 4,
  SUPER_ADMIN: 5
};

module.exports = {
  sessionConfig,
  hashPassword,
  comparePassword,
  requireAuth,
  requireRole,
  USER_ROLES,
  redisClient
};
