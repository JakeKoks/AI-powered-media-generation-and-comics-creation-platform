// Professional authentication routes with comprehensive validation
const express = require('express');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');
const { query } = require('../config/database');
const { hashPassword, comparePassword, USER_ROLES } = require('../middleware/auth');

const router = express.Router();

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: {
    success: false,
    error: 'Too many authentication attempts. Please try again later.',
    code: 'RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Input validation middleware
const validateRegistration = [
  body('username')
    .isLength({ min: 3, max: 30 })
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username must be 3-30 characters, alphanumeric and underscores only'),
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email required'),
  body('password')
    .isLength({ min: 8 })
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must be 8+ characters with uppercase, lowercase, number, and special character'),
  body('fullName')
    .isLength({ min: 2, max: 100 })
    .trim()
    .withMessage('Full name required (2-100 characters)')
];

const validateLogin = [
  body('username')
    .notEmpty()
    .withMessage('Username required'),
  body('password')
    .notEmpty()
    .withMessage('Password required')
];

// Helper function to handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details: errors.array()
    });
  }
  next();
};

// POST /api/auth/register - User registration
router.post('/register', authLimiter, validateRegistration, handleValidationErrors, async (req, res) => {
  try {
    const { username, email, password, fullName } = req.body;

    // Check if user already exists
    const existingUser = await query(
      'SELECT id FROM users WHERE username = $1 OR email = $2',
      [username, email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Username or email already exists',
        code: 'USER_EXISTS'
      });
    }

    // Hash password
    const hashedPassword = await hashPassword(password);

    // Create user
    const result = await query(
      `INSERT INTO users (username, email, password_hash, full_name, role, created_at) 
       VALUES ($1, $2, $3, $4, $5, NOW()) 
       RETURNING id, username, email, full_name, role, created_at`,
      [username, email, hashedPassword, fullName, USER_ROLES.USER]
    );

    const user = result.rows[0];

    // Create session
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.userRole = user.role;

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.full_name,
          role: user.role,
          createdAt: user.created_at
        }
      }
    });

    console.log(`✅ New user registered: ${username} (ID: ${user.id})`);

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during registration',
      code: 'REGISTRATION_ERROR'
    });
  }
});

// POST /api/auth/login - User login
router.post('/login', authLimiter, validateLogin, handleValidationErrors, async (req, res) => {
  try {
    const { username, password } = req.body;

    // Find user
    const result = await query(
      'SELECT id, username, email, password_hash, full_name, role, is_active, last_login FROM users WHERE username = $1 OR email = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials',
        code: 'INVALID_CREDENTIALS'
      });
    }

    const user = result.rows[0];

    // Check if account is active
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        error: 'Account is disabled',
        code: 'ACCOUNT_DISABLED'
      });
    }

    // Verify password
    const isPasswordValid = await comparePassword(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Update last login
    await query('UPDATE users SET last_login = NOW() WHERE id = $1', [user.id]);

    // Create session
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.userRole = user.role;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.full_name,
          role: user.role,
          lastLogin: user.last_login
        }
      }
    });

    console.log(`✅ User logged in: ${user.username} (ID: ${user.id})`);

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error during login',
      code: 'LOGIN_ERROR'
    });
  }
});

// POST /api/auth/logout - User logout
router.post('/logout', (req, res) => {
  if (req.session) {
    const username = req.session.username;
    req.session.destroy((err) => {
      if (err) {
        console.error('Logout error:', err);
        return res.status(500).json({
          success: false,
          error: 'Could not log out',
          code: 'LOGOUT_ERROR'
        });
      }

      res.clearCookie('aicomics.sid');
      res.json({
        success: true,
        message: 'Logout successful'
      });

      console.log(`✅ User logged out: ${username}`);
    });
  } else {
    res.json({
      success: true,
      message: 'Already logged out'
    });
  }
});

// GET /api/auth/me - Get current user
router.get('/me', (req, res) => {
  if (req.session && req.session.userId) {
    res.json({
      success: true,
      data: {
        user: {
          id: req.session.userId,
          username: req.session.username,
          role: req.session.userRole
        },
        authenticated: true
      }
    });
  } else {
    res.json({
      success: true,
      data: {
        user: null,
        authenticated: false
      }
    });
  }
});

// GET /api/auth/status - Authentication status check
router.get('/status', async (req, res) => {
  try {
    if (!req.session || !req.session.userId) {
      return res.json({
        success: true,
        data: {
          authenticated: false,
          user: null
        }
      });
    }

    // Get fresh user data
    const result = await query(
      'SELECT id, username, email, full_name, role, is_active, last_login FROM users WHERE id = $1',
      [req.session.userId]
    );

    if (result.rows.length === 0 || !result.rows[0].is_active) {
      // User not found or disabled, destroy session
      req.session.destroy();
      return res.json({
        success: true,
        data: {
          authenticated: false,
          user: null
        }
      });
    }

    const user = result.rows[0];
    res.json({
      success: true,
      data: {
        authenticated: true,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          fullName: user.full_name,
          role: user.role,
          lastLogin: user.last_login
        }
      }
    });

  } catch (error) {
    console.error('Auth status error:', error);
    res.status(500).json({
      success: false,
      error: 'Could not check authentication status',
      code: 'AUTH_STATUS_ERROR'
    });
  }
});

module.exports = router;
