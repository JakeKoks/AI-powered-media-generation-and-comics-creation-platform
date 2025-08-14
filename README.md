# AI Media & Comics Website

## 🎯 Project Overview

A production-ready web application for AI-powered media generation and comics creation with comprehensive user management, role-based access control, and smart home integration.

### ✨ Key Features
- **AI Media Generation**: Images, videos, and GIFs from prompts
- **Comics Builder**: Multi-panel comics with AI-generated content
- **5-Rank User System**: Granular permissions and access control
- **Admin Panel**: Complete user and system management
- **Smart Home Integration**: Home Assistant API integration
- **GDPR Compliance**: Privacy controls and data management

### 🏗️ Technical Stack
- **Frontend**: React 18 + TypeScript + Tailwind CSS
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL 15 + Prisma ORM
- **AI Worker**: Python + CUDA + ComfyUI
- **Storage**: MinIO (S3-compatible)
- **Queue**: BullMQ + Redis
- **Monitoring**: Prometheus + Grafana

---

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 20+
- Python 3.11+ (for AI worker)
- NVIDIA GPU with CUDA support (recommended)

### 1. Clone and Setup
```bash
git clone <repository-url>
cd ai-media-comics
npm install
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
# DATABASE_URL, REDIS_URL, MINIO_CONFIG, JWT_SECRET, etc.
```

### 3. Start Development Environment
```bash
# Start all services
make dev

# Or manually:
docker-compose up -d
npm run dev
```

### 4. Access Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:4000
- **Admin Panel**: http://localhost:3000/admin
- **MinIO Console**: http://localhost:9001
- **Grafana**: http://localhost:3001

---

## 📁 Project Structure

```
ai-media-comics/
├── apps/                          # Applications
│   ├── frontend/                  # React + TypeScript
│   ├── backend/                   # Express + TypeScript API
│   ├── ai-worker/                 # Python AI worker
│   └── admin-panel/               # Admin dashboard
├── packages/                      # Shared packages
│   ├── ui/                        # Shared UI components
│   ├── types/                     # TypeScript definitions
│   └── utils/                     # Utility functions
├── infrastructure/                # Infrastructure as code
│   ├── docker/                    # Docker configurations
│   └── monitoring/                # Prometheus/Grafana
├── docs/                          # Documentation
│   ├── specifications/            # Project specs
│   ├── architecture/              # Technical docs
│   └── deployment/                # Deployment guides
├── docker-compose.yml             # Development environment
├── Makefile                       # Common commands
└── README.md                      # This file
```

---

## 🛠️ Development Commands

### Environment Management
```bash
make dev              # Start development environment
make prod             # Start production environment
make down             # Stop all services
make clean            # Clean up containers and volumes
make reset            # Reset entire environment
```

### Database Operations
```bash
make db-migrate       # Run database migrations
make db-seed          # Seed database with test data
make db-reset         # Reset database
make db-backup        # Create database backup
```

### Testing
```bash
make test             # Run all tests
make test-unit        # Run unit tests
make test-integration # Run integration tests
make test-e2e         # Run E2E tests
```

### Code Quality
```bash
make lint             # Run linting
make format           # Format code
make type-check       # TypeScript type checking
```

---

## 🔧 Configuration

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/aicomics
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret

# Storage
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# AI Worker
COMFYUI_URL=http://localhost:8188
GPU_ENABLED=true

# External APIs
HOME_ASSISTANT_URL=http://homeassistant:8123
HOME_ASSISTANT_TOKEN=your-ha-token
```

### Docker Services
- **PostgreSQL**: Database on port 5432
- **Redis**: Cache and job queue on port 6379
- **MinIO**: S3-compatible storage on ports 9000/9001
- **Backend**: API server on port 4000
- **Frontend**: React app on port 3000
- **AI Worker**: Python worker on port 8000

---

## 👥 User Roles & Permissions

### Role Hierarchy (1-5)
1. **Guest**: View public content only
2. **User**: Basic AI generation, personal content
3. **Creator**: Extended AI features, comics publishing
4. **Admin**: User management, content moderation
5. **Super Admin**: Full system access

### Permission System
```typescript
enum Permission {
  // Content
  CREATE_CONTENT = 'content:create',
  EDIT_OWN_CONTENT = 'content:edit:own',
  EDIT_ALL_CONTENT = 'content:edit:all',
  DELETE_OWN_CONTENT = 'content:delete:own',
  DELETE_ALL_CONTENT = 'content:delete:all',
  
  // AI Generation
  GENERATE_IMAGES = 'ai:generate:images',
  GENERATE_VIDEOS = 'ai:generate:videos',
  GENERATE_COMICS = 'ai:generate:comics',
  
  // User Management
  VIEW_USERS = 'users:view',
  EDIT_USERS = 'users:edit',
  DELETE_USERS = 'users:delete',
  
  // System
  VIEW_ANALYTICS = 'system:analytics',
  MANAGE_SETTINGS = 'system:settings',
  ACCESS_ADMIN_PANEL = 'system:admin',
}
```

---

## 🔒 Security Features

### Authentication
- JWT access tokens (15 minutes)
- Refresh tokens (30 days)
- Argon2id password hashing
- Rate limiting (IP + user based)
- Session management with Redis

### Data Protection
- HTTPS everywhere with HSTS
- Content Security Policy headers
- Input validation with Zod schemas
- SQL injection prevention
- File upload security (virus scanning, MIME validation)

### Privacy Controls
- **Public**: Visible on explore page
- **Unlisted**: Direct link access only
- **Private**: Owner and admin access only

---

## 🚀 Deployment

### Production Deployment
```bash
# Build production images
make build-prod

# Deploy to production
make deploy-prod

# Update production
make update-prod
```

### Health Checks
- **Backend**: GET /health
- **Database**: Connection test
- **Redis**: Ping test
- **MinIO**: Bucket access test
- **AI Worker**: Model loading test

### Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and alerts
- **Logs**: Centralized logging with retention
- **Uptime**: 99.5% SLO target

---

## 📚 Documentation

### API Documentation
- **Swagger UI**: http://localhost:4000/docs
- **OpenAPI Spec**: Available at `/api/docs.json`
- **Postman Collection**: `docs/api/postman-collection.json`

### Architecture Docs
- [System Architecture](docs/architecture/SYSTEM_ARCHITECTURE.md)
- [Database Schema](docs/architecture/DATABASE_SCHEMA.md)
- [API Design](docs/architecture/API_DESIGN.md)

### User Guides
- [Getting Started](docs/user-guides/GETTING_STARTED.md)
- [AI Generation](docs/user-guides/AI_GENERATION.md)
- [Comics Builder](docs/user-guides/COMICS_BUILDER.md)
- [Admin Panel](docs/user-guides/ADMIN_PANEL.md)

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Make changes with proper commit messages
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

### Commit Convention
```
feat: add new AI model integration
fix: resolve authentication bug
docs: update API documentation
test: add unit tests for user service
refactor: improve error handling
```

### Code Style
- TypeScript for type safety
- ESLint + Prettier for formatting
- Conventional commits
- Test coverage > 80%

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- **Documentation**: Check the `docs/` directory
- **Issues**: Create an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions

---

**Ready to build amazing AI-powered content!** 🎨🤖
