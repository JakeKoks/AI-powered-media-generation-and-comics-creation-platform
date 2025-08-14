-- Migration script to enhance existing database schema
-- Add missing columns to existing users table

-- Add missing columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS full_name VARCHAR(100),
ADD COLUMN IF NOT EXISTS role INTEGER DEFAULT 2,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS profile_image_url TEXT,
ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0;

-- Add constraints for new columns
ALTER TABLE users 
ADD CONSTRAINT users_role_check CHECK (role >= 1 AND role <= 5);

-- Update existing users to have full_name if it's NULL
UPDATE users SET full_name = username WHERE full_name IS NULL;

-- Make full_name NOT NULL after updating
ALTER TABLE users 
ALTER COLUMN full_name SET NOT NULL;

-- Create missing tables if they don't exist
CREATE TABLE IF NOT EXISTS media (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255),
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    width INTEGER,
    height INTEGER,
    duration REAL,
    metadata JSONB DEFAULT '{}',
    tags TEXT[],
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT media_type_check CHECK (media_type IN ('image', 'video', 'gif', 'comic')),
    CONSTRAINT media_size_check CHECK (file_size > 0)
);

-- Update ai_jobs table with missing columns
ALTER TABLE ai_jobs 
ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS queue_time TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS start_time TIMESTAMP,
ADD COLUMN IF NOT EXISTS completion_time TIMESTAMP,
ADD COLUMN IF NOT EXISTS estimated_duration INTEGER,
ADD COLUMN IF NOT EXISTS actual_duration INTEGER,
ADD COLUMN IF NOT EXISTS worker_id VARCHAR(100);

-- Add constraints
ALTER TABLE ai_jobs 
ADD CONSTRAINT jobs_priority_check CHECK (priority >= 1 AND priority <= 10);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_media_user_id ON media(user_id);
CREATE INDEX IF NOT EXISTS idx_media_type ON media(media_type);
CREATE INDEX IF NOT EXISTS idx_media_public ON media(is_public);
CREATE INDEX IF NOT EXISTS idx_media_created_at ON media(created_at);
CREATE INDEX IF NOT EXISTS idx_jobs_priority ON ai_jobs(priority);
CREATE INDEX IF NOT EXISTS idx_jobs_queue_time ON ai_jobs(queue_time);

-- Add updated_at trigger for media table
DROP TRIGGER IF EXISTS update_media_updated_at ON media;
CREATE TRIGGER update_media_updated_at 
    BEFORE UPDATE ON media 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user if it doesn't exist
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

-- Add sample media data
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

-- Create view for user statistics
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

COMMENT ON TABLE users IS 'User accounts with role-based access control';
COMMENT ON TABLE media IS 'Generated media files and metadata';
COMMENT ON COLUMN users.role IS '1=Guest, 2=User, 3=Creator, 4=Admin, 5=SuperAdmin';
COMMENT ON COLUMN ai_jobs.priority IS 'Job priority: 1=highest, 10=lowest, 5=default';
