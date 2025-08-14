#!/bin/bash
# 🤖 Raspberry Pi Setup Script for AI Comics Platform

echo "🤖 Setting up Raspberry Pi for AI Comics Platform..."

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo apt install docker-compose-plugin -y
    echo "✅ Docker Compose installed successfully"
else
    echo "✅ Docker Compose already installed"
fi

# Install additional tools
echo "🛠️ Installing additional tools..."
sudo apt install -y git curl htop iotop ufw fail2ban

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3000/tcp  # Frontend
sudo ufw allow 3001/tcp  # Backend
sudo ufw allow 3002/tcp  # Grafana
sudo ufw allow 9000/tcp  # MinIO
sudo ufw allow 9001/tcp  # MinIO Console
sudo ufw --force enable

# Create application directory
echo "📁 Creating application directories..."
mkdir -p ~/ai-comics-platform
cd ~/ai-comics-platform

# Clone repository (if not already present)
if [ ! -d ".git" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/JakeKoks/AI-powered-media-generation-and-comics-creation-platform.git .
fi

# Create environment file from template
if [ ! -f ".env.pi" ]; then
    echo "⚙️ Creating environment configuration..."
    cp .env.pi.template .env.pi
    echo "📝 Please edit .env.pi with your configuration values"
    echo "   nano .env.pi"
else
    echo "✅ Environment file already exists"
fi

# Create required directories
echo "📁 Creating required directories..."
mkdir -p logs generated cache

# Set up log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/ai-comics > /dev/null <<EOF
/home/$USER/ai-comics-platform/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
}
EOF

# Configure system limits for better performance
echo "⚡ Optimizing system performance..."
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "net.core.rmem_max=16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max=16777216" | sudo tee -a /etc/sysctl.conf

# Set static IP (optional)
PI_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Current IP address: $PI_IP"
echo "💡 Make sure to configure a static IP in your router settings"
echo "   Recommended: 192.168.1.50"

# Final instructions
echo ""
echo "🎉 Raspberry Pi setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit environment file: nano .env.pi"
echo "2. Configure your router to assign static IP 192.168.1.50 to this Pi"
echo "3. Set up port forwarding in your router (optional for internet access):"
echo "   - Port 80 → 192.168.1.50:3000 (HTTP)"
echo "   - Port 443 → 192.168.1.50:3000 (HTTPS)"
echo "4. Set up your Windows PC AI worker"
echo "5. Deploy the application: docker-compose -f docker-compose.pi.yml --env-file .env.pi up -d"
echo ""
echo "📊 After deployment, access:"
echo "   - Frontend: http://192.168.1.50:3000"
echo "   - Backend API: http://192.168.1.50:3001"
echo "   - Grafana: http://192.168.1.50:3002"
echo "   - MinIO: http://192.168.1.50:9001"
echo ""
echo "🔄 Reboot recommended to apply all changes: sudo reboot"
echo ""
echo "💖 Happy AI Comics generation!"
