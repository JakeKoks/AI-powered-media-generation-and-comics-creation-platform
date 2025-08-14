-- 🗄️ AI Comics Platform Database Schema
-- Simple schema for local development with basic authentication

-- Create database (if not exists)
-- CREATE DATABASE ai_comics_db;

-- Use the database
-- \c ai_comics_db;

-- 👥 Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- 📚 Comics table
CREATE TABLE IF NOT EXISTS comics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    status VARCHAR(20) DEFAULT 'draft', -- draft, published, processing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 📊 User sessions table (for analytics - optional)
CREATE TABLE IF NOT EXISTS user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- 🎨 AI Generation Jobs table (for future AI integration)
CREATE TABLE IF NOT EXISTS ai_jobs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    comic_id INTEGER REFERENCES comics(id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL, -- text_to_image, image_to_comic, etc.
    prompt TEXT,
    parameters JSONB,
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
    result_url VARCHAR(500),
    error_message TEXT,
    processing_time INTEGER, -- in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 📈 Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_comics_user_id ON comics(user_id);
CREATE INDEX IF NOT EXISTS idx_comics_created_at ON comics(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_user_id ON ai_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_status ON ai_jobs(status);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);

-- 🔧 Create a function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 🔄 Create triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comics_updated_at 
    BEFORE UPDATE ON comics 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 👤 Insert a test user for development (password: 'test123')
INSERT INTO users (username, email, password_hash) 
VALUES (
    'testuser', 
    'test@example.com', 
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
) ON CONFLICT (username) DO NOTHING;

-- 📚 Insert some test comics
INSERT INTO comics (user_id, title, description) 
SELECT 
    u.id,
    'My First Comic',
    'A test comic created during development'
FROM users u 
WHERE u.username = 'testuser'
ON CONFLICT DO NOTHING;

-- 🎯 Create a view for user statistics (useful for admin dashboard)
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.created_at,
    u.last_login,
    COUNT(c.id) as comics_count,
    COUNT(aj.id) as ai_jobs_count,
    MAX(c.created_at) as last_comic_created
FROM users u
LEFT JOIN comics c ON u.id = c.user_id
LEFT JOIN ai_jobs aj ON u.id = aj.user_id
GROUP BY u.id, u.username, u.email, u.created_at, u.last_login;

-- 📊 Create a view for system metrics (for monitoring dashboard)
CREATE OR REPLACE VIEW system_metrics AS
SELECT 
    'total_users' as metric_name,
    COUNT(*) as metric_value,
    NOW() as collected_at
FROM users
WHERE is_active = true

UNION ALL

SELECT 
    'total_comics' as metric_name,
    COUNT(*) as metric_value,
    NOW() as collected_at
FROM comics

UNION ALL

SELECT 
    'comics_today' as metric_name,
    COUNT(*) as metric_value,
    NOW() as collected_at
FROM comics
WHERE created_at >= CURRENT_DATE

UNION ALL

SELECT 
    'active_sessions' as metric_name,
    COUNT(*) as metric_value,
    NOW() as collected_at
FROM user_sessions
WHERE expires_at > NOW();

-- 🎉 Success message
DO $$
BEGIN
    RAISE NOTICE '🎉 AI Comics database schema created successfully!';
    RAISE NOTICE '👤 Test user created: username=testuser, password=test123';
    RAISE NOTICE '📚 Test comic created for development';
    RAISE NOTICE '📊 Views created for statistics and monitoring';
    RAISE NOTICE '🚀 Database is ready for the AI Comics platform!';
END $$;
