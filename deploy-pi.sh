#!/bin/bash
# Raspberry Pi Production Deployment Script
# deploy-pi.sh

set -euo pipefail

echo "🚀 Starting AI Comics Production Deployment on Raspberry Pi"
echo "=========================================================="

# Create secrets directory if it doesn't exist
mkdir -p ./secrets

# Generate secure passwords if they don't exist
if [ ! -f "./secrets/db_password.txt" ]; then
    echo "🔐 Generating database password..."
    openssl rand -base64 32 > ./secrets/db_password.txt
fi

if [ ! -f "./secrets/jwt_secret.txt" ]; then
    echo "🔐 Generating JWT secret..."
    openssl rand -base64 64 > ./secrets/jwt_secret.txt
fi

if [ ! -f "./secrets/jwt_refresh_secret.txt" ]; then
    echo "🔐 Generating JWT refresh secret..."
    openssl rand -base64 64 > ./secrets/jwt_refresh_secret.txt
fi

if [ ! -f "./secrets/session_secret.txt" ]; then
    echo "🔐 Generating session secret..."
    openssl rand -base64 32 > ./secrets/session_secret.txt
fi

# Read database password for connection string
DB_PASSWORD=$(cat ./secrets/db_password.txt)

# Create database URL
echo "postgresql://aicomics_user:${DB_PASSWORD}@postgres:5432/aicomics" > ./secrets/db_url.txt

# Set proper permissions (CRITICAL for security)
chmod 600 ./secrets/*
echo "🔒 Secret files secured with proper permissions"

# Verify Docker and Docker Compose are available
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed. Aborting." >&2; exit 1; }

# Pull latest images
echo "📦 Pulling latest Docker images..."
docker-compose -f docker-compose.raspberry-pi.yml pull

# Build backend image
echo "🏗️ Building backend image..."
docker-compose -f docker-compose.raspberry-pi.yml build backend

# Stop existing containers if running
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose.raspberry-pi.yml down

# Start production stack
echo "🚀 Starting production stack..."
docker-compose -f docker-compose.raspberry-pi.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🏥 Checking service health..."
docker-compose -f docker-compose.raspberry-pi.yml ps

# Show logs for verification
echo "📋 Recent logs:"
docker-compose -f docker-compose.raspberry-pi.yml logs --tail=20

echo ""
echo "✅ Production deployment complete!"
echo "🌐 Backend API: http://$(hostname -I | awk '{print $1}'):3000"
echo "📊 Metrics: http://$(hostname -I | awk '{print $1}'):9090"
echo ""
echo "🔧 Useful commands:"
echo "  View logs: docker-compose -f docker-compose.raspberry-pi.yml logs -f"
echo "  Stop: docker-compose -f docker-compose.raspberry-pi.yml down"
echo "  Restart: docker-compose -f docker-compose.raspberry-pi.yml restart"
echo ""
echo "🔐 IMPORTANT: Backup your secrets directory!"
echo "  Secrets location: ./secrets/"
