# 💻 Windows PC Setup Script for AI Comics Platform
# Run this in PowerShell as Administrator

Write-Host "💻 Setting up Windows PC as AI Worker for AI Comics Platform..." -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script needs to be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for NVIDIA GPU
$nvidiaSmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
if ($nvidiaSmi) {
    Write-Host "✅ NVIDIA GPU detected" -ForegroundColor Green
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
} else {
    Write-Host "⚠️  NVIDIA GPU not detected or drivers not installed" -ForegroundColor Yellow
    Write-Host "AI generation will be MUCH slower without GPU acceleration" -ForegroundColor Red
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# Check Docker Desktop
$dockerDesktop = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerDesktop) {
    Write-Host "✅ Docker Desktop is running" -ForegroundColor Green
} else {
    Write-Host "❌ Docker Desktop not found or not running" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "Make sure to enable WSL2 integration" -ForegroundColor Yellow
    $install = Read-Host "Continue with setup anyway? (y/N)"
    if ($install -ne "y" -and $install -ne "Y") {
        exit 1
    }
}

# Check Python
$python = Get-Command "python" -ErrorAction SilentlyContinue
if ($python) {
    $pythonVersion = python --version
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  Python not found in PATH" -ForegroundColor Yellow
    Write-Host "Install Python 3.10+ from: https://www.python.org/downloads/" -ForegroundColor Yellow
}

# Check Git
$git = Get-Command "git" -ErrorAction SilentlyContinue
if ($git) {
    Write-Host "✅ Git is installed" -ForegroundColor Green
} else {
    Write-Host "❌ Git not found" -ForegroundColor Red
    Write-Host "Install Git from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Create project directory
$projectPath = "$env:USERPROFILE\ai-comics-platform"
Write-Host "📁 Creating project directory: $projectPath" -ForegroundColor Cyan

if (!(Test-Path $projectPath)) {
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
}

Set-Location $projectPath

# Clone repository if not exists
if (!(Test-Path ".git")) {
    Write-Host "📥 Cloning repository..." -ForegroundColor Cyan
    git clone https://github.com/JakeKoks/AI-powered-media-generation-and-comics-creation-platform.git .
}

# Create required directories
Write-Host "📁 Creating required directories..." -ForegroundColor Cyan
@("models", "generated", "processed", "cache", "logs", "tmp", "downloads") | ForEach-Object {
    if (!(Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "  Created: $_" -ForegroundColor Gray
    }
}

# Create environment file from template
if (!(Test-Path ".env.pc")) {
    Write-Host "⚙️ Creating environment configuration..." -ForegroundColor Cyan
    Copy-Item ".env.pc.template" ".env.pc"
    Write-Host "📝 Please edit .env.pc with your configuration values" -ForegroundColor Yellow
    Write-Host "   notepad .env.pc" -ForegroundColor Gray
} else {
    Write-Host "✅ Environment file already exists" -ForegroundColor Green
}

# Configure Windows Firewall
Write-Host "🔒 Configuring Windows Firewall..." -ForegroundColor Cyan
try {
    # Allow AI Worker port
    New-NetFirewallRule -DisplayName "AI Comics Worker" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "AI Comics Metrics" -Direction Inbound -Protocol TCP -LocalPort 9092 -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "AI Comics File Server" -Direction Inbound -Protocol TCP -LocalPort 8083 -Action Allow -ErrorAction SilentlyContinue
    Write-Host "✅ Firewall rules created" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not configure firewall automatically" -ForegroundColor Yellow
    Write-Host "Please manually allow ports 8080, 9092, 8083 in Windows Firewall" -ForegroundColor Yellow
}

# Configure static IP recommendation
$currentIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*" | Where-Object {$_.IPAddress -like "192.168.*"})[0].IPAddress
Write-Host "🌐 Current IP address: $currentIP" -ForegroundColor Cyan
Write-Host "💡 Configure static IP 192.168.1.100 in your router settings" -ForegroundColor Yellow

# Install NVIDIA Container Toolkit (if NVIDIA GPU present)
if ($nvidiaSmi) {
    Write-Host "🐳 Checking NVIDIA Container Toolkit..." -ForegroundColor Cyan
    $dockerInfo = docker info 2>$null | Select-String "nvidia"
    if ($dockerInfo) {
        Write-Host "✅ NVIDIA Container Toolkit is configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  NVIDIA Container Toolkit not detected" -ForegroundColor Yellow
        Write-Host "Install from: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html" -ForegroundColor Yellow
        Write-Host "This is required for GPU acceleration in Docker containers" -ForegroundColor Yellow
    }
}

# Create PowerShell aliases for easy management
$profilePath = $PROFILE.CurrentUserAllHosts
if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$aliases = @"

# AI Comics Platform Aliases
function Start-AIWorker { Set-Location '$projectPath'; docker-compose -f docker-compose.pc.yml --env-file .env.pc up -d }
function Stop-AIWorker { Set-Location '$projectPath'; docker-compose -f docker-compose.pc.yml down }
function Restart-AIWorker { Stop-AIWorker; Start-AIWorker }
function Show-AIWorkerLogs { Set-Location '$projectPath'; docker-compose -f docker-compose.pc.yml logs -f }
function Show-AIWorkerStatus { Set-Location '$projectPath'; docker-compose -f docker-compose.pc.yml ps }

"@

Add-Content -Path $profilePath -Value $aliases

# Performance optimizations
Write-Host "⚡ Applying performance optimizations..." -ForegroundColor Cyan

# Set high performance power plan
try {
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "✅ Set high performance power plan" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not set power plan automatically" -ForegroundColor Yellow
}

# Final instructions
Write-Host ""
Write-Host "🎉 Windows PC setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Edit environment file: notepad .env.pc" -ForegroundColor White
Write-Host "2. Configure static IP 192.168.1.100 in your router settings" -ForegroundColor White
Write-Host "3. Make sure your Raspberry Pi is set up at 192.168.1.50" -ForegroundColor White
Write-Host "4. Download AI models (will be done automatically on first run)" -ForegroundColor White
Write-Host "5. Start AI worker: Start-AIWorker" -ForegroundColor White
Write-Host ""
Write-Host "🎮 PowerShell Commands Available:" -ForegroundColor Cyan
Write-Host "   Start-AIWorker      - Start all AI services" -ForegroundColor Gray
Write-Host "   Stop-AIWorker       - Stop all AI services" -ForegroundColor Gray  
Write-Host "   Restart-AIWorker    - Restart all services" -ForegroundColor Gray
Write-Host "   Show-AIWorkerLogs   - View live logs" -ForegroundColor Gray
Write-Host "   Show-AIWorkerStatus - Check service status" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 After deployment, services will be available at:" -ForegroundColor Cyan
Write-Host "   - AI Worker API: http://192.168.1.100:8080" -ForegroundColor White
Write-Host "   - Metrics: http://192.168.1.100:9092" -ForegroundColor White
Write-Host "   - File Server: http://192.168.1.100:8083" -ForegroundColor White
Write-Host ""
Write-Host "💡 Restart PowerShell to use the new aliases" -ForegroundColor Yellow
Write-Host ""
Write-Host "💖 Happy AI generation!" -ForegroundColor Magenta

Read-Host "Press Enter to continue"
