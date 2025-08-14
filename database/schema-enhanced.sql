-- Enhanced database schema for AI Comics platform
-- Professional-grade schema with proper indexes and constraints

-- Enable UUID extension for better ID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table with comprehensive user management
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role INTEGER NOT NULL DEFAULT 2, -- 1=Guest, 2=User, 3=Creator, 4=Admin, 5=SuperAdmin
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    profile_image_url TEXT,
    preferences JSONB DEFAULT '{}',
    last_login TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT users_role_check CHECK (role >= 1 AND role <= 5),
    CONSTRAINT users_username_format CHECK (username ~ '^[a-zA-Z0-9_]+$'),
    CONSTRAINT users_email_format CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$')
);

-- Media storage table for generated content
CREATE TABLE IF NOT EXISTS media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    media_type VARCHAR(20) NOT NULL, -- 'image', 'video', 'gif', 'comic'
    width INTEGER,
    height INTEGER,
    duration REAL, -- For videos
    metadata JSONB DEFAULT '{}',
    tags TEXT[],
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT media_type_check CHECK (media_type IN ('image', 'video', 'gif', 'comic')),
    CONSTRAINT media_size_check CHECK (file_size > 0),
    CONSTRAINT media_dimensions_check CHECK (
        (width IS NULL AND height IS NULL) OR 
        (width > 0 AND height > 0)
    )
);

-- AI generation jobs table for queue management
CREATE TABLE IF NOT EXISTS ai_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    priority INTEGER DEFAULT 5,
    input_data JSONB NOT NULL,
    output_data JSONB,
    progress INTEGER DEFAULT 0,
    error_message TEXT,
    worker_id VARCHAR(100),
    estimated_duration INTEGER, -- seconds
    actual_duration INTEGER, -- seconds
    queue_time TIMESTAMP DEFAULT NOW(),
    start_time TIMESTAMP,
    completion_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT jobs_type_check CHECK (job_type IN ('image_generation', 'video_generation', 'gif_generation', 'comic_creation', 'upscaling')),
    CONSTRAINT jobs_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    CONSTRAINT jobs_priority_check CHECK (priority >= 1 AND priority <= 10),
    CONSTRAINT jobs_progress_check CHECK (progress >= 0 AND progress <= 100)
);

-- User sessions table for session management
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    location JSONB,
    is_active BOOLEAN DEFAULT true,
    last_activity TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT sessions_expires_check CHECK (expires_at > created_at)
);

-- System audit log for security and debugging
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

CREATE INDEX IF NOT EXISTS idx_media_user_id ON media(user_id);
CREATE INDEX IF NOT EXISTS idx_media_type ON media(media_type);
CREATE INDEX IF NOT EXISTS idx_media_public ON media(is_public);
CREATE INDEX IF NOT EXISTS idx_media_featured ON media(is_featured);
CREATE INDEX IF NOT EXISTS idx_media_created_at ON media(created_at);
CREATE INDEX IF NOT EXISTS idx_media_tags ON media USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_jobs_user_id ON ai_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON ai_jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_type ON ai_jobs(job_type);
CREATE INDEX IF NOT EXISTS idx_jobs_priority ON ai_jobs(priority);
CREATE INDEX IF NOT EXISTS idx_jobs_queue_time ON ai_jobs(queue_time);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON user_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON user_sessions(expires_at);

CREATE INDEX IF NOT EXISTS idx_audit_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_logs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_media_updated_at BEFORE UPDATE ON media FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON ai_jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user (change password in production!)
INSERT INTO users (username, email, password_hash, full_name, role, is_active, email_verified) 
VALUES (
    'admin',
    'admin@aicomics.local',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeOxNaY/YPNWJgWwe', -- password: admin123!@#
    'System Administrator',
    5,
    true,
    true
) ON CONFLICT (username) DO NOTHING;

-- Insert test user for development
INSERT INTO users (username, email, password_hash, full_name, role, is_active, email_verified) 
VALUES (
    'testuser',
    'test@aicomics.local',
    '$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: password
    'Test User',
    2,
    true,
    true
) ON CONFLICT (username) DO NOTHING;

-- Add some sample data for testing
INSERT INTO media (user_id, filename, original_filename, file_path, file_size, mime_type, media_type, width, height, metadata, is_public)
SELECT 
    u.id,
    'sample_image_1.jpg',
    'generated_artwork.jpg',
    '/media/images/sample_image_1.jpg',
    1024000,
    'image/jpeg',
    'image',
    1024,
    1024,
    '{"prompt": "A beautiful landscape", "model": "SDXL", "steps": 30}',
    true
FROM users u WHERE u.username = 'testuser'
ON CONFLICT DO NOTHING;

-- View for user statistics
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.username,
    u.full_name,
    u.role,
    u.created_at,
    u.last_login,
    u.login_count,
    COUNT(DISTINCT m.id) as media_count,
    COUNT(DISTINCT j.id) as jobs_count,
    COUNT(DISTINCT j.id) FILTER (WHERE j.status = 'completed') as completed_jobs,
    COUNT(DISTINCT j.id) FILTER (WHERE j.status = 'failed') as failed_jobs
FROM users u
LEFT JOIN media m ON u.id = m.user_id
LEFT JOIN ai_jobs j ON u.id = j.user_id
GROUP BY u.id, u.username, u.full_name, u.role, u.created_at, u.last_login, u.login_count;

-- Function to cleanup old sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_sessions WHERE expires_at < NOW() OR last_activity < (NOW() - INTERVAL '30 days');
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON TABLE users IS 'User accounts with role-based access control';
COMMENT ON TABLE media IS 'Generated media files and metadata';
COMMENT ON TABLE ai_jobs IS 'AI generation job queue and tracking';
COMMENT ON TABLE user_sessions IS 'Active user sessions for security';
COMMENT ON TABLE audit_logs IS 'System audit trail for security and debugging';

COMMENT ON COLUMN users.role IS '1=Guest, 2=User, 3=Creator, 4=Admin, 5=SuperAdmin';
COMMENT ON COLUMN ai_jobs.priority IS 'Job priority: 1=highest, 10=lowest, 5=default';
COMMENT ON COLUMN ai_jobs.progress IS 'Job completion percentage (0-100)';
