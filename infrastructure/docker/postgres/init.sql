-- Initialize database for AI Comics Website
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create initial user roles enum type
CREATE TYPE user_role AS ENUM ('guest', 'user', 'creator', 'admin', 'super_admin');

-- Create job status enum type  
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');

-- Create media privacy enum type
CREATE TYPE media_privacy AS ENUM ('public', 'unlisted', 'private');

-- Set timezone
SET timezone = 'UTC';
