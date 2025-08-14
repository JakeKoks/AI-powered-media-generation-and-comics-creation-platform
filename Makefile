# AI Media & Comics Website - Makefile
# Common development and deployment commands

.PHONY: help dev prod down clean reset test lint format setup

# Default target
help:
	@echo "AI Media & Comics Website - Available Commands:"
	@echo ""
	@echo "Development:"
	@echo "  make dev           Start development environment"
	@echo "  make setup         Complete setup (install + docker + db)"
	@echo "  make test          Run all tests"
	@echo "  make test-unit     Run unit tests only"
	@echo "  make test-e2e      Run E2E tests only"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-dev    Start Docker development services"
	@echo "  make docker-prod   Start Docker production services"
	@echo "  make down          Stop all Docker services"
	@echo "  make clean         Clean Docker containers and volumes"
	@echo "  make reset         Reset entire environment"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate    Run database migrations"
	@echo "  make db-seed       Seed database with test data"
	@echo "  make db-reset      Reset database completely"
	@echo "  make db-backup     Create database backup"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint          Run linting"
	@echo "  make format        Format code"
	@echo "  make type-check    TypeScript type checking"
	@echo ""
	@echo "Git:"
	@echo "  make git-setup     Setup git hooks and configuration"
	@echo "  make commit        Interactive commit with testing"

# Development Commands
dev: docker-dev
	@echo "Starting development servers..."
	@npm run dev

setup: install docker-dev db-migrate db-seed
	@echo "✅ Complete setup finished!"
	@echo "🚀 Run 'make dev' to start development"

install:
	@echo "📦 Installing dependencies..."
	@npm install

# Docker Commands
docker-dev:
	@echo "🐳 Starting Docker development environment..."
	@docker-compose up -d
	@echo "⏳ Waiting for services to be ready..."
	@sleep 10
	@docker-compose ps

docker-prod:
	@echo "🐳 Starting Docker production environment..."
	@docker-compose -f docker-compose.prod.yml up -d

down:
	@echo "🛑 Stopping Docker services..."
	@docker-compose down

clean:
	@echo "🧹 Cleaning Docker containers and volumes..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f

reset: clean
	@echo "🔄 Resetting entire environment..."
	@docker volume prune -f
	@rm -rf node_modules apps/*/node_modules packages/*/node_modules
	@echo "✅ Environment reset complete. Run 'make setup' to rebuild."

# Database Commands
db-migrate:
	@echo "📊 Running database migrations..."
	@npm run db:migrate

db-seed:
	@echo "🌱 Seeding database with test data..."
	@npm run db:seed

db-reset:
	@echo "🔄 Resetting database..."
	@npm run db:reset

db-backup:
	@echo "💾 Creating database backup..."
	@mkdir -p backups
	@docker exec ai-comics-db pg_dump -U postgres aicomics > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Database backup created in backups/"

# Testing Commands
test:
	@echo "🧪 Running all tests..."
	@npm run test

test-unit:
	@echo "🧪 Running unit tests..."
	@npm run test:unit

test-integration:
	@echo "🧪 Running integration tests..."
	@npm run test:integration

test-e2e:
	@echo "🧪 Running E2E tests..."
	@npm run test:e2e

# Code Quality Commands
lint:
	@echo "🔍 Running linting..."
	@npm run lint

lint-fix:
	@echo "🔧 Fixing linting issues..."
	@npm run lint:fix

format:
	@echo "💅 Formatting code..."
	@npm run format

type-check:
	@echo "📝 Running TypeScript type checking..."
	@npm run type-check

# Git Commands
git-setup:
	@echo "🔧 Setting up git hooks..."
	@npm run prepare
	@git config core.hooksPath .husky
	@echo "✅ Git hooks configured"

commit: test lint
	@echo "✅ All checks passed. Ready to commit!"
	@git add .
	@echo "Please enter your commit message:"
	@read -p "Commit message: " msg; git commit -m "$$msg"

# Health Checks
health:
	@echo "🏥 Checking service health..."
	@echo "Backend API:" && curl -f http://localhost:4000/health || echo "❌ Backend not responding"
	@echo "Frontend:" && curl -f http://localhost:3000 || echo "❌ Frontend not responding"
	@echo "MinIO:" && curl -f http://localhost:9000/minio/health/live || echo "❌ MinIO not responding"
	@echo "Redis:" && docker exec ai-comics-redis redis-cli ping || echo "❌ Redis not responding"
	@echo "PostgreSQL:" && docker exec ai-comics-db pg_isready -U postgres || echo "❌ PostgreSQL not responding"

# Logs
logs:
	@echo "📋 Showing service logs..."
	@docker-compose logs -f

logs-backend:
	@docker-compose logs -f backend

logs-frontend:
	@docker-compose logs -f frontend

logs-ai-worker:
	@docker-compose logs -f ai-worker

# Development Tools
shell-backend:
	@docker exec -it ai-comics-backend /bin/bash

shell-db:
	@docker exec -it ai-comics-db psql -U postgres -d aicomics

shell-redis:
	@docker exec -it ai-comics-redis redis-cli

# Production Commands (use with caution)
deploy-prod: test lint docker-prod
	@echo "🚀 Deploying to production..."
	@echo "⚠️  Make sure you've updated environment variables!"

# Backup and Restore
backup-all:
	@echo "💾 Creating full backup..."
	@make db-backup
	@tar -czf backups/media_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz minio-data/
	@echo "✅ Full backup completed"

# Monitoring
monitor:
	@echo "📊 Opening monitoring dashboards..."
	@echo "Grafana: http://localhost:3001 (admin/admin123)"
	@echo "Prometheus: http://localhost:9090"
	@echo "MinIO Console: http://localhost:9001 (minioadmin/minioadmin123)"
