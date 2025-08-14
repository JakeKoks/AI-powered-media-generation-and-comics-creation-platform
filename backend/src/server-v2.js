// AI Comics Backend Server - Professional Edition v2.0
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const session = require('express-session');
const client = require('prom-client');
require('dotenv').config();

// Import configurations and middleware
const { testConnection, query } = require('./config/database');
const { sessionConfig } = require('./middleware/auth');
const authRoutes = require('./routes/auth');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// 📊 PROMETHEUS METRICS SETUP
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Custom metrics for our AI Comics platform
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeUsers = new client.Gauge({
  name: 'active_users_total',
  help: 'Number of currently active users'
});

const aiJobsProcessed = new client.Counter({
  name: 'ai_jobs_processed_total',
  help: 'Total number of AI jobs processed',
  labelNames: ['job_type', 'status']
});

const databaseConnections = new client.Gauge({
  name: 'database_connections_active',
  help: 'Number of active database connections'
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(activeUsers);
register.registerMetric(aiJobsProcessed);
register.registerMetric(databaseConnections);

// 🛡️ SECURITY MIDDLEWARE
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false
}));

// 🌐 CORS CONFIGURATION
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// 📝 LOGGING
app.use(morgan('combined', {
  skip: (req, res) => req.url === '/health' || req.url === '/metrics'
}));

// 🗜️ COMPRESSION
app.use(compression());

// 📊 REQUEST PARSING
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 🔄 SESSION MANAGEMENT
app.use(session(sessionConfig));

// 🚦 RATE LIMITING
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: {
    success: false,
    error: 'Too many requests. Please try again later.',
    code: 'RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true,
  legacyHeaders: false
});

app.use('/api/', generalLimiter);

// 📊 METRICS MIDDLEWARE
app.use((req, res, next) => {
  const startTime = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - startTime) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    httpRequestDuration
      .labels(req.method, route, res.statusCode.toString())
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, route, res.statusCode.toString())
      .inc();
  });
  
  next();
});

// 🏠 HEALTH CHECK ENDPOINT
app.get('/health', async (req, res) => {
  try {
    const startTime = Date.now();
    
    // Test database connection
    const dbHealthy = await testConnection();
    const dbResponseTime = Date.now() - startTime;
    
    // Check Redis connection (session store)
    let redisHealthy = false;
    try {
      const { redisClient } = require('./middleware/auth');
      await redisClient.ping();
      redisHealthy = true;
    } catch (err) {
      console.warn('Redis health check failed:', err.message);
    }
    
    // Get system metrics
    const memUsage = process.memoryUsage();
    const uptime = process.uptime();
    
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: process.env.npm_package_version || '1.0.0',
      uptime: uptime,
      environment: process.env.NODE_ENV || 'development',
      services: {
        database: {
          status: dbHealthy ? 'healthy' : 'unhealthy',
          responseTime: `${dbResponseTime}ms`
        },
        redis: {
          status: redisHealthy ? 'healthy' : 'unhealthy'
        },
        memory: {
          rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
          heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
          heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`
        }
      }
    };
    
    const overallHealthy = dbHealthy && redisHealthy;
    
    res.status(overallHealthy ? 200 : 503).json({
      success: overallHealthy,
      data: health
    });
    
  } catch (error) {
    console.error('Health check error:', error);
    res.status(503).json({
      success: false,
      error: 'Health check failed',
      timestamp: new Date().toISOString()
    });
  }
});

// 📊 METRICS ENDPOINT FOR PROMETHEUS
app.get('/metrics', async (req, res) => {
  try {
    // Update active users metric
    if (req.session?.userId) {
      // In a real app, you'd query active sessions from Redis
      activeUsers.set(1); // Simplified for now
    }
    
    // Update database connections metric
    // This would typically come from your connection pool
    databaseConnections.set(5); // Simplified for now
    
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    console.error('Metrics error:', error);
    res.status(500).end();
  }
});

// 🔐 AUTHENTICATION ROUTES
app.use('/api/auth', authRoutes);

// 📊 DASHBOARD API - Basic user stats
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    if (!req.session?.userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    const userId = req.session.userId;
    
    // Get user statistics
    const [userResult, mediaResult, jobsResult] = await Promise.all([
      query('SELECT username, full_name, role, created_at, last_login FROM users WHERE id = $1', [userId]),
      query('SELECT COUNT(*) as count, SUM(file_size) as total_size FROM media WHERE user_id = $1', [userId]),
      query(`
        SELECT 
          COUNT(*) as total_jobs,
          COUNT(*) FILTER (WHERE status = 'completed') as completed_jobs,
          COUNT(*) FILTER (WHERE status = 'failed') as failed_jobs,
          COUNT(*) FILTER (WHERE status = 'pending') as pending_jobs
        FROM ai_jobs WHERE user_id = $1
      `, [userId])
    ]);

    const userData = userResult.rows[0];
    const mediaData = mediaResult.rows[0];
    const jobsData = jobsResult.rows[0];

    res.json({
      success: true,
      data: {
        user: {
          username: userData.username,
          fullName: userData.full_name,
          role: userData.role,
          memberSince: userData.created_at,
          lastLogin: userData.last_login
        },
        stats: {
          mediaFiles: parseInt(mediaData.count || 0),
          totalStorageUsed: parseInt(mediaData.total_size || 0),
          totalJobs: parseInt(jobsData.total_jobs || 0),
          completedJobs: parseInt(jobsData.completed_jobs || 0),
          failedJobs: parseInt(jobsData.failed_jobs || 0),
          pendingJobs: parseInt(jobsData.pending_jobs || 0)
        }
      }
    });

  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({
      success: false,
      error: 'Could not retrieve dashboard statistics',
      code: 'DASHBOARD_ERROR'
    });
  }
});

// 📁 MEDIA API - Get user's media
app.get('/api/media', async (req, res) => {
  try {
    if (!req.session?.userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    const userId = req.session.userId;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = (page - 1) * limit;
    const mediaType = req.query.type || null;

    let query_text = `
      SELECT id, filename, original_filename, file_path, file_size, 
             mime_type, media_type, width, height, metadata, tags,
             is_public, download_count, like_count, created_at
      FROM media 
      WHERE user_id = $1
    `;
    const params = [userId];

    if (mediaType) {
      query_text += ` AND media_type = $${params.length + 1}`;
      params.push(mediaType);
    }

    query_text += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await query(query_text, params);
    
    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) FROM media WHERE user_id = $1';
    const countParams = [userId];
    if (mediaType) {
      countQuery += ' AND media_type = $2';
      countParams.push(mediaType);
    }
    
    const countResult = await query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        media: result.rows,
        pagination: {
          page,
          limit,
          total: totalCount,
          pages: Math.ceil(totalCount / limit)
        }
      }
    });

  } catch (error) {
    console.error('Media API error:', error);
    res.status(500).json({
      success: false,
      error: 'Could not retrieve media files',
      code: 'MEDIA_ERROR'
    });
  }
});

// 🎯 ROOT ENDPOINT
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'AI Comics Backend API v2.0',
    timestamp: new Date().toISOString(),
    documentation: '/api/docs',
    health: '/health',
    metrics: '/metrics',
    endpoints: {
      authentication: '/api/auth/*',
      dashboard: '/api/dashboard/*',
      media: '/api/media',
      // Coming soon:
      // jobs: '/api/jobs',
      // ai: '/api/ai/*',
      // admin: '/api/admin/*'
    }
  });
});

// 🚫 404 HANDLER
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    code: 'NOT_FOUND',
    path: req.path,
    method: req.method
  });
});

// 🛠️ ERROR HANDLER
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  
  res.status(err.statusCode || 500).json({
    success: false,
    error: process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : err.message,
    code: err.code || 'INTERNAL_ERROR',
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// 🚀 SERVER STARTUP
const startServer = async () => {
  try {
    console.log('🚀 Starting AI Comics Backend Server...');
    
    // Test database connection
    const dbConnected = await testConnection();
    if (!dbConnected) {
      throw new Error('Database connection failed');
    }
    
    // Start server
    app.listen(PORT, () => {
      console.log('');
      console.log('🎉 AI Comics Backend Server Started!');
      console.log('');
      console.log(`📍 Server URL: http://localhost:${PORT}`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/health`);
      console.log(`📊 Metrics: http://localhost:${PORT}/metrics`);
      console.log(`🔐 Auth API: http://localhost:${PORT}/api/auth/*`);
      console.log(`📊 Dashboard: http://localhost:${PORT}/api/dashboard/stats`);
      console.log(`🖼️ Media API: http://localhost:${PORT}/api/media`);
      console.log('');
      console.log('✅ Ready for frontend connections!');
      console.log('✅ Prometheus metrics enabled');
      console.log('✅ Session-based authentication active');
      console.log('✅ Professional security headers applied');
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('📴 SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('📴 SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

// Start the server
startServer();
