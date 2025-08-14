# Two-Solution Architecture Documentation

## Overview
This project implements a two-tier deployment architecture designed to solve the PostgreSQL authentication issues while providing both development convenience and production security.

---

## 🛠️ Solution 1: Local Development (Windows)

### Purpose
Eliminates Windows-to-Docker networking issues by containerizing the Node.js application alongside PostgreSQL in the same Docker network.

### Architecture
```
Windows Host
└── Docker Network (ai-comics-network)
    ├── PostgreSQL Container (postgres:5432)
    ├── Redis Container (redis:6379)
    ├── Backend Container (Node.js)
    └── MinIO Container (minio:9000)
```

### Key Benefits
- ✅ **No networking issues** - All services in same Docker network
- ✅ **Fast development** - Hot reload with volume mounting
- ✅ **Consistent environment** - Same as production networking
- ✅ **Easy debugging** - Direct container access

### Quick Start
```powershell
# Method 1: Quick Setup Script
.\quick-dev-setup.ps1

# Method 2: Manual Docker Compose
docker-compose down
docker-compose up --build
```

### Development URLs
- **Backend API**: http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **Database**: localhost:5432 (from host)
- **Redis**: localhost:6379 (from host)
- **MinIO**: http://localhost:9000

---

## 🚀 Solution 2: Production (Raspberry Pi)

### Purpose
Secure, production-ready deployment with secrets management, resource limits, and hardened security configuration.

### Architecture
```
Raspberry Pi
├── Docker Network (172.20.0.0/16)
│   ├── PostgreSQL (aicomics_user, SCRAM-SHA-256)
│   ├── Redis (password-protected)
│   ├── Backend (resource-limited)
│   └── MinIO (secrets-based auth)
├── Secrets Management (/run/secrets/)
├── SSL/TLS Termination (Nginx)
└── Monitoring & Metrics
```

### Security Features
- 🔐 **Docker Secrets** - No passwords in environment variables
- 🛡️ **Network Isolation** - Specific subnet, deny-all rules
- 🔒 **SCRAM-SHA-256** - Strong PostgreSQL authentication
- 👤 **Non-root containers** - Security-hardened user permissions
- 📊 **Resource limits** - Prevent resource exhaustion
- 🚫 **Disabled commands** - Redis dangerous commands removed

### Production Deployment
```bash
# Raspberry Pi deployment
chmod +x deploy-pi.sh
./deploy-pi.sh

# Windows testing of production setup
.\deploy-pi.ps1
```

### Production URLs
- **Backend API**: http://[pi-ip]:3000
- **Metrics**: http://[pi-ip]:9090
- **MinIO Console**: http://[pi-ip]:9001

---

## 📁 File Structure

### Development Files
```
backend/
├── Dockerfile              # Development container
├── .env                    # Development environment
└── .dockerignore           # Docker build optimization

docker-compose.yml          # Development stack
quick-dev-setup.ps1         # Quick development setup
```

### Production Files
```
backend/
└── Dockerfile.prod         # Production-hardened container

config/
├── pg_hba_prod.conf        # Production PostgreSQL security
└── redis_prod.conf         # Production Redis configuration

secrets/                    # Production secrets (auto-generated)
├── db_password.txt
├── db_url.txt
├── jwt_secret.txt
├── jwt_refresh_secret.txt
└── session_secret.txt

docker-compose.raspberry-pi.yml  # Production stack
deploy-pi.sh                     # Raspberry Pi deployment
deploy-pi.ps1                    # Windows production test
```

---

## 🔧 Configuration Differences

| Feature | Development | Production |
|---------|-------------|------------|
| **Database User** | `postgres` | `aicomics_user` |
| **Authentication** | Simple password | SCRAM-SHA-256 + secrets |
| **Network** | Bridge (default) | Custom subnet (172.20.0.0/16) |
| **Secrets** | Environment vars | Docker secrets |
| **Resources** | Unlimited | CPU/Memory limits |
| **Security** | Development-friendly | Hardened (deny-all rules) |
| **Monitoring** | Optional | Prometheus metrics |

---

## 🚨 Security Considerations

### Development Security
- Uses simple passwords for ease of development
- Permissive network rules for debugging
- Trust authentication for local connections
- Not suitable for production use

### Production Security
- **Secrets Management**: All sensitive data in Docker secrets
- **Network Isolation**: Only container network allowed
- **Authentication**: Strong SCRAM-SHA-256 with unique users
- **Access Control**: Deny-all rules with specific exceptions
- **Resource Protection**: CPU and memory limits prevent DoS
- **Audit Trail**: Comprehensive logging and monitoring

---

## 🔄 Migration Path

### Development → Production
1. **Code remains identical** - Same Node.js application
2. **Environment differs** - Configuration through Docker secrets
3. **Security hardens** - Automatic with production deployment
4. **Monitoring enabled** - Prometheus metrics activated

### Deployment Process
```bash
# 1. Development testing
docker-compose up --build

# 2. Production deployment  
./deploy-pi.sh

# 3. Health verification
curl http://[pi-ip]:3000/health
```

---

## 🐛 Troubleshooting

### Common Issues

#### Development
- **Port conflicts**: Ensure ports 3000, 5432, 6379 are free
- **Volume permissions**: Docker volume mounting issues on Windows
- **Build failures**: Check Dockerfile.dev for Node.js version compatibility

#### Production
- **Secret generation**: Ensure OpenSSL is available for random generation
- **Network connectivity**: Verify Docker daemon and compose versions
- **Resource constraints**: Monitor Raspberry Pi CPU/memory usage

### Debug Commands
```bash
# View container logs
docker-compose logs -f backend

# Container shell access
docker exec -it ai-comics-backend-prod /bin/sh

# Network inspection
docker network inspect [network_name]

# Resource monitoring
docker stats
```

---

## 📊 Performance Expectations

### Development Environment
- **Startup Time**: ~30 seconds (including database initialization)
- **Memory Usage**: ~200MB for backend container
- **Hot Reload**: File changes reflected within 2-3 seconds

### Production Environment (Raspberry Pi 4)
- **Startup Time**: ~60 seconds (including health checks)
- **Memory Usage**: ~256MB (with limits enforced)
- **Concurrent Users**: 50-100 (depending on workload)
- **Response Time**: <200ms for API calls (local network)

---

## 🎯 Future Enhancements

### Planned Features
- **Load Balancing**: Multiple backend containers
- **SSL/TLS**: Automatic certificate management
- **Backup Automation**: Database backup scheduling
- **CI/CD Pipeline**: Automated testing and deployment
- **Log Aggregation**: Centralized logging with ELK stack

### Scalability Path
1. **Horizontal scaling**: Multiple backend instances
2. **Database clustering**: PostgreSQL replication
3. **CDN integration**: Static asset optimization
4. **Microservices**: Service decomposition as needed

---

*This architecture provides both development convenience and production security while maintaining code compatibility between environments.*
