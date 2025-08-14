# Quick Development Setup Script
Write-Host "Setting up containerized development environment..." -ForegroundColor Green

# Create .env for backend with container networking
$envContent = @"
DATABASE_URL=postgresql://postgres:postgres123@postgres:5432/aicomics
NODE_ENV=development
REDIS_URL=redis://redis:6379
PORT=3000
JWT_SECRET=dev-jwt-secret-change-in-production
CORS_ORIGIN=http://localhost:3001
"@

$envContent | Out-File -FilePath "backend/.env" -Encoding UTF8
Write-Host "Created backend/.env with container networking" -ForegroundColor Yellow

# Stop existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down

# Build and start new setup
Write-Host "Building and starting backend..." -ForegroundColor Yellow
docker-compose up --build -d

Write-Host "Setup complete! Backend running on http://localhost:3000" -ForegroundColor Green
Write-Host "Check logs with: docker-compose logs backend" -ForegroundColor Cyan
