#!/bin/bash
# Quick Development Setup
# quick-dev-setup.sh

echo "🚀 Quick Development Setup - AI Comics Backend"
echo "=============================================="

# Update backend environment for container networking
echo "📝 Updating backend environment..."
cat > backend/.env << EOF
# Development Environment - Container Networking
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://postgres:postgres123@postgres:5432/aicomics
REDIS_URL=redis://redis:6379
JWT_SECRET=dev-jwt-secret-change-in-production
CORS_ORIGIN=http://localhost:3001
EOF

echo "🐳 Rebuilding and starting containers..."

# Stop existing containers
docker-compose down

# Rebuild and start with container networking
docker-compose up --build -d postgres redis

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Build and start backend
docker-compose up --build backend

echo "✅ Development setup complete!"
echo "🌐 Backend: http://localhost:3000"
echo "🏥 Health check: http://localhost:3000/health"
