# PowerShell deployment script for Windows testing of production setup
# deploy-pi.ps1

Write-Host "🚀 Starting AI Comics Production Deployment Test" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Create secrets directory
if (-not (Test-Path "./secrets")) {
    New-Item -ItemType Directory -Path "./secrets"
}

# Generate secure passwords (Windows version)
Write-Host "🔐 Generating secure secrets..." -ForegroundColor Yellow

# Database password
if (-not (Test-Path "./secrets/db_password.txt")) {
    $dbPassword = [System.Web.Security.Membership]::GeneratePassword(32, 8)
    $dbPassword | Out-File -FilePath "./secrets/db_password.txt" -Encoding UTF8 -NoNewline
}

# JWT secrets
if (-not (Test-Path "./secrets/jwt_secret.txt")) {
    $jwtSecret = [System.Web.Security.Membership]::GeneratePassword(64, 16)
    $jwtSecret | Out-File -FilePath "./secrets/jwt_secret.txt" -Encoding UTF8 -NoNewline
}

if (-not (Test-Path "./secrets/jwt_refresh_secret.txt")) {
    $jwtRefreshSecret = [System.Web.Security.Membership]::GeneratePassword(64, 16)
    $jwtRefreshSecret | Out-File -FilePath "./secrets/jwt_refresh_secret.txt" -Encoding UTF8 -NoNewline
}

# Session secret
if (-not (Test-Path "./secrets/session_secret.txt")) {
    $sessionSecret = [System.Web.Security.Membership]::GeneratePassword(32, 8)
    $sessionSecret | Out-File -FilePath "./secrets/session_secret.txt" -Encoding UTF8 -NoNewline
}

# Create database URL
$dbPassword = Get-Content "./secrets/db_password.txt" -Raw
$dbUrl = "postgresql://aicomics_user:$($dbPassword)@postgres:5432/aicomics"
$dbUrl | Out-File -FilePath "./secrets/db_url.txt" -Encoding UTF8 -NoNewline

Write-Host "🔒 Secrets generated successfully" -ForegroundColor Green

# Deploy with Docker Compose
Write-Host "📦 Building and starting production stack..." -ForegroundColor Yellow

try {
    # Build the backend
    docker-compose -f docker-compose.raspberry-pi.yml build backend
    
    # Start the stack
    docker-compose -f docker-compose.raspberry-pi.yml up -d
    
    Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Check status
    Write-Host "🏥 Service Status:" -ForegroundColor Green
    docker-compose -f docker-compose.raspberry-pi.yml ps
    
    Write-Host "📋 Recent Logs:" -ForegroundColor Green
    docker-compose -f docker-compose.raspberry-pi.yml logs --tail=10
    
    Write-Host ""
    Write-Host "✅ Production deployment test complete!" -ForegroundColor Green
    Write-Host "🌐 Backend API: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "📊 Metrics: http://localhost:9090" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
