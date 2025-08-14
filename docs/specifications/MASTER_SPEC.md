# AI Media & Comics Website - Master Specification

## 🎯 Project Overview

**Goal**: Build a production-ready web application for AI-powered media generation and comics creation with comprehensive user management, role-based access control, and smart home integration.

### Core Features
- **AI Media Generation**: Images, videos, and GIFs from prompts or prompt + uploaded photos
- **AI Comics Builder**: Multi-panel comics with AI-generated content, speech bubbles, and captions
- **5-Rank User System**: Super Admin, Admin, Creator, User, Guest
- **Advanced Admin Panel**: Complete user management with sidebar navigation
- **Photo/Media Upload**: Privacy controls (Public/Private/Unlisted)
- **Smart Home Integration**: Home Assistant API integration (admin-only)
- **Internationalization**: Polish/English language support
- **RODO/GDPR Compliance**: Cookie consent, data export, right to be forgotten

## 🏗️ Technical Stack

### **Frontend**
- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite (faster than Webpack)
- **Styling**: Tailwind CSS + Headless UI
- **State Management**: Zustand + React Query
- **Routing**: React Router v6
- **Internationalization**: react-i18next
- **WebSocket**: Socket.io-client for real-time updates
- **Testing**: Vitest + React Testing Library

### **Backend**
- **Runtime**: Node.js 20 LTS
- **Framework**: Express.js with TypeScript
- **Database**: PostgreSQL 15 with Prisma ORM
- **Authentication**: JWT (access/refresh tokens)
- **File Storage**: MinIO (S3-compatible)
- **Job Queue**: BullMQ with Redis
- **Real-time**: Socket.io
- **API Documentation**: Swagger/OpenAPI
- **Testing**: Jest + Supertest

### **AI Worker**
- **Runtime**: Python 3.11 + CUDA 12
- **AI Framework**: ComfyUI for workflow-based generation
- **Image Models**: SDXL Turbo, Flux, IP-Adapter
- **Video Models**: HunyuanVideo, AnimateDiff
- **Upscaling**: Real-ESRGAN, GFPGAN
- **Queue**: Python worker consuming BullMQ jobs
- **GPU**: NVIDIA with CUDA support

### **Infrastructure**
- **Containerization**: Docker + Docker Compose
- **Database**: PostgreSQL 15
- **Cache/Queue**: Redis 7
- **Storage**: MinIO (local S3)
- **Reverse Proxy**: Nginx
- **Monitoring**: Prometheus + Grafana
- **Logging**: Winston + ELK Stack

## 📋 Port Allocation (Freed from Previous Project)

**Previous project used:**
- Frontend: 3005 ✅ (now available)
- Backend: 5000 ✅ (now available)
- PostgreSQL: 5432 ✅ (now available)

**New project ports:**
- Frontend: 3000 (React dev server)
- Backend API: 4000 (Express server)
- PostgreSQL: 5432 (database)
- Redis: 6379 (cache/queue)
- MinIO: 9000 (S3 storage) + 9001 (console)
- AI Worker: 8000 (internal API)
- Nginx: 80/443 (production proxy)
- Grafana: 3001 (monitoring)
- Prometheus: 9090 (metrics)

## 🚀 Implementation Plan (17-Day Timeline)

### **Phase 0: Foundation Setup** (Day 1)
**Goal**: Create monorepo structure and basic Docker setup

**Tasks:**
- [ ] Create monorepo with apps/ and packages/ structure
- [ ] Setup Docker Compose with all services
- [ ] Configure development environment
- [ ] Setup linting, formatting, and git hooks
- [ ] Create Makefile for common commands

**Deliverables:**
- Working Docker environment
- Monorepo structure
- Development workflow setup

### **Phase 1: Database & Authentication** (Day 2-3)
**Goal**: Core data models and secure authentication

**Tasks:**
- [ ] Design Prisma schema (User, Role, Media, Comic, Job models)
- [ ] Implement JWT authentication with refresh tokens
- [ ] Setup 5-rank role system (Super Admin, Admin, Creator, User, Guest)
- [ ] Create database migrations and seed data
- [ ] Implement rate limiting with Redis

**Deliverables:**
- Complete database schema
- Authentication system
- Role-based access control

### **Phase 2: File Storage & Media Management** (Day 4-5)
**Goal**: Secure media upload and storage system

**Tasks:**
- [ ] Setup MinIO S3-compatible storage
- [ ] Implement chunked file uploads
- [ ] Create media privacy controls (Public/Private/Unlisted)
- [ ] Add virus scanning and validation
- [ ] Generate thumbnails and metadata

**Deliverables:**
- Media upload system
- Privacy controls
- Storage optimization

### **Phase 3: Job Queue & AI Infrastructure** (Day 6-7)
**Goal**: Asynchronous job processing for AI generation

**Tasks:**
- [ ] Setup BullMQ with Redis for job management
- [ ] Create AI worker architecture
- [ ] Implement WebSocket for real-time progress
- [ ] Setup ComfyUI environment with GPU support
- [ ] Create job lifecycle management

**Deliverables:**
- Job queue system
- AI worker foundation
- Real-time progress updates

### **Phase 4: AI Image Generation** (Day 8-9)
**Goal**: Core AI image generation capabilities

**Tasks:**
- [ ] Integrate SDXL/Flux models
- [ ] Implement prompt-to-image generation
- [ ] Add image-to-image with IP-Adapter
- [ ] Create upscaling pipeline with Real-ESRGAN
- [ ] Setup style presets and negative prompts

**Deliverables:**
- Working image generation
- Multiple AI models
- Image enhancement features

### **Phase 5: AI Video & GIF Generation** (Day 10-11)
**Goal**: Video and animated content generation

**Tasks:**
- [ ] Integrate HunyuanVideo for video generation
- [ ] Implement video-to-GIF conversion
- [ ] Add frame interpolation and smoothing
- [ ] Create video preview and thumbnails
- [ ] Optimize video encoding and compression

**Deliverables:**
- Video generation system
- GIF creation pipeline
- Video optimization

### **Phase 6: Comics Builder** (Day 12-13)
**Goal**: AI-powered comics creation tool

**Tasks:**
- [ ] Design comic panel layout system
- [ ] Create speech bubble editor
- [ ] Implement AI character consistency with IP-Adapter
- [ ] Add text-to-comic generation
- [ ] Create comic export to PDF/PNG

**Deliverables:**
- Comics builder interface
- Multi-panel generation
- Comic export functionality

### **Phase 7: Frontend Core Pages** (Day 14-15)
**Goal**: Essential user-facing pages and components

**Tasks:**
- [ ] Create landing page with feature showcase
- [ ] Build authentication pages (login/register)
- [ ] Implement main studio/generation interface
- [ ] Create media gallery with filtering
- [ ] Add user profile and settings

**Deliverables:**
- Complete user interface
- Generation tools
- Media management

### **Phase 8: Admin Panel** (Day 16)
**Goal**: Comprehensive admin dashboard

**Tasks:**
- [ ] Create admin sidebar navigation
- [ ] Build user management interface
- [ ] Add system monitoring dashboard
- [ ] Implement content moderation tools
- [ ] Create audit logs and analytics

**Deliverables:**
- Full admin panel
- User management
- System monitoring

### **Phase 9: Smart Home Integration** (Day 17)
**Goal**: Home Assistant integration for admins

**Tasks:**
- [ ] Create Home Assistant API client
- [ ] Build admin-only smart home dashboard
- [ ] Implement device control interface
- [ ] Add automation triggers
- [ ] Setup secure token management

**Deliverables:**
- Smart home integration
- Device control panel
- Security implementation

### **Phase 10: Internationalization** (Day 18)
**Goal**: Multi-language support

**Tasks:**
- [ ] Setup react-i18next framework
- [ ] Create Polish/English translations
- [ ] Implement language switching
- [ ] Localize date/time formats
- [ ] Add RTL support preparation

**Deliverables:**
- Complete i18n system
- Polish/English support
- Language switching

### **Phase 11: GDPR/RODO Compliance** (Day 19)
**Goal**: Legal compliance and privacy

**Tasks:**
- [ ] Implement cookie consent banner
- [ ] Create privacy policy and terms
- [ ] Add data export functionality
- [ ] Implement right to be forgotten
- [ ] Setup audit trail for data operations

**Deliverables:**
- GDPR compliance
- Privacy controls
- Legal pages

### **Phase 12: Testing & Quality Assurance** (Day 20-21)
**Goal**: Comprehensive testing and bug fixes

**Tasks:**
- [ ] Write backend API tests (Jest/Supertest)
- [ ] Create frontend component tests (Vitest/RTL)
- [ ] Implement E2E tests (Playwright)
- [ ] Performance testing with k6
- [ ] Security testing and penetration testing

**Deliverables:**
- Complete test suite
- Performance validation
- Security assessment

### **Phase 13: Production Deployment** (Day 22-23)
**Goal**: Production-ready deployment

**Tasks:**
- [ ] Setup production Docker configurations
- [ ] Configure Nginx reverse proxy
- [ ] Implement SSL certificates
- [ ] Setup monitoring and alerting
- [ ] Create backup and recovery procedures

**Deliverables:**
- Production deployment
- Monitoring system
- Backup procedures

## 🔒 Security Requirements

### **Authentication & Authorization**
- JWT access tokens (15min) + refresh tokens (30 days)
- Argon2id password hashing
- Rate limiting: 100 req/min per IP, 1000 req/min per user
- Session management with Redis
- 2FA support (TOTP)

### **Input Validation**
- Zod schemas for all API inputs
- File type and size validation
- Malware scanning for uploads
- SQL injection prevention
- XSS protection with Content Security Policy

### **Data Protection**
- Encryption at rest for sensitive data
- HTTPS everywhere with HSTS
- Secure headers (OWASP recommendations)
- Privacy controls for all user content
- GDPR/RODO compliance

## 📊 Performance Requirements

### **Response Times**
- Page load: < 2.5s on 4G connection
- API responses: < 500ms (excluding AI jobs)
- Image generation: 10-30s depending on complexity
- Video generation: 30-120s depending on length
- Real-time updates: < 2s latency

### **Scalability**
- Support 1000+ concurrent users
- 50+ simultaneous AI jobs
- 100GB+ media storage
- 99.5% uptime SLO
- Horizontal scaling ready

## 🎨 User Experience

### **Design Principles**
- Mobile-first responsive design
- Intuitive AI generation workflow
- Real-time progress feedback
- Accessibility (WCAG 2.1 AA)
- Dark/light theme support

### **Key User Flows**
1. **Registration** → Email verification → Role assignment
2. **AI Generation** → Prompt entry → Real-time progress → Result download
3. **Comics Creation** → Panel layout → AI generation → Text editing → Export
4. **Admin Management** → User overview → Role changes → Content moderation

## 📈 Success Metrics

### **Technical KPIs**
- 99.5% uptime
- < 2.5s average page load
- < 500ms API response time
- 95% successful AI generations
- Zero critical security vulnerabilities

### **User Engagement**
- Daily active users
- AI generations per user
- Comics created per week
- User retention rate
- Feature adoption rates

---

*This specification serves as the complete guide for building a production-ready AI Media & Comics Website with enterprise-grade features, security, and performance.*
