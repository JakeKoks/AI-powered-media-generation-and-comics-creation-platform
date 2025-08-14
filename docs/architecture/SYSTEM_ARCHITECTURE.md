# System Architecture - AI Media & Comics Website

## 🏗️ High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   AI Worker     │
│   React + TS    │────│   Express + TS  │────│   Python + GPU  │
│   Port: 3000    │    │   Port: 4000    │    │   Port: 8000    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │   PostgreSQL    │    │     Redis       │
│   Reverse Proxy │    │    Database     │    │  Cache & Queue  │
│   Port: 80/443  │    │   Port: 5432    │    │   Port: 6379    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │     MinIO       │
                       │   S3 Storage    │
                       │  Port: 9000/1   │
                       └─────────────────┘
```

## 🔄 Data Flow Architecture

### **Request Flow**
1. **Client Request** → Nginx Reverse Proxy
2. **Nginx** → Frontend (static) or Backend API (dynamic)
3. **Backend** → PostgreSQL (data) + Redis (cache/sessions)
4. **Backend** → MinIO (file storage)
5. **Backend** → AI Worker (via Redis queue)

### **AI Generation Flow**
```
User Submit → Backend API → Redis Queue → AI Worker → ComfyUI → Result → MinIO → WebSocket Update → Frontend
```

### **Authentication Flow**
```
Login → JWT Access Token (15min) → Protected Routes → Refresh Token (30 days) → New Access Token
```

## 💾 Database Architecture

### **Core Tables**
```sql
-- User Management
users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE NOT NULL,
  username VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR NOT NULL,
  role_id INTEGER REFERENCES roles(id),
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  profile_image_url VARCHAR,
  preferences JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Role-Based Access Control
roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR UNIQUE NOT NULL,
  level INTEGER NOT NULL, -- 1-5 hierarchy
  permissions JSONB NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Media Storage
media (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  filename VARCHAR NOT NULL,
  original_filename VARCHAR NOT NULL,
  mime_type VARCHAR NOT NULL,
  file_size BIGINT NOT NULL,
  privacy VARCHAR CHECK (privacy IN ('public', 'unlisted', 'private')),
  metadata JSONB,
  thumbnail_url VARCHAR,
  storage_path VARCHAR NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- AI Generation Jobs
jobs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL, -- image, video, gif, comic
  status VARCHAR DEFAULT 'pending',
  progress INTEGER DEFAULT 0,
  parameters JSONB NOT NULL,
  result_media_id UUID REFERENCES media(id),
  error_message TEXT,
  processing_time INTEGER, -- seconds
  created_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP,
  completed_at TIMESTAMP
);

-- Comics
comics (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR NOT NULL,
  description TEXT,
  panels JSONB NOT NULL, -- panel layout and content
  is_published BOOLEAN DEFAULT false,
  privacy VARCHAR DEFAULT 'private',
  metadata JSONB,
  thumbnail_url VARCHAR,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User Sessions
user_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR NOT NULL,
  ip_address INET,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Audit Logs
audit_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action VARCHAR NOT NULL,
  resource_type VARCHAR NOT NULL,
  resource_id VARCHAR,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### **Indexes for Performance**
```sql
-- User lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role_id ON users(role_id);

-- Media queries
CREATE INDEX idx_media_user_id ON media(user_id);
CREATE INDEX idx_media_privacy ON media(privacy);
CREATE INDEX idx_media_created_at ON media(created_at DESC);

-- Job processing
CREATE INDEX idx_jobs_user_id ON jobs(user_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_type ON jobs(type);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);

-- Audit trails
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
```

## 🔧 Backend Architecture

### **Layered Architecture**
```
├── src/
│   ├── controllers/        # Request handlers
│   │   ├── auth.controller.ts
│   │   ├── media.controller.ts
│   │   ├── ai.controller.ts
│   │   └── admin.controller.ts
│   ├── services/           # Business logic
│   │   ├── auth.service.ts
│   │   ├── media.service.ts
│   │   ├── ai.service.ts
│   │   └── queue.service.ts
│   ├── models/             # Data models (Prisma)
│   │   ├── user.model.ts
│   │   ├── media.model.ts
│   │   └── job.model.ts
│   ├── middleware/         # Express middleware
│   │   ├── auth.middleware.ts
│   │   ├── validation.middleware.ts
│   │   ├── rate-limit.middleware.ts
│   │   └── error.middleware.ts
│   ├── routes/             # API routes
│   │   ├── auth.routes.ts
│   │   ├── media.routes.ts
│   │   ├── ai.routes.ts
│   │   └── admin.routes.ts
│   ├── utils/              # Utility functions
│   │   ├── jwt.util.ts
│   │   ├── password.util.ts
│   │   ├── storage.util.ts
│   │   └── validation.util.ts
│   ├── config/             # Configuration
│   │   ├── database.config.ts
│   │   ├── redis.config.ts
│   │   └── storage.config.ts
│   └── types/              # TypeScript types
│       ├── auth.types.ts
│       ├── media.types.ts
│       └── api.types.ts
```

### **API Design Patterns**
```typescript
// RESTful API with consistent response format
interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  pagination?: {
    page: number;
    limit: number;
    total: number;
  };
}

// Standard error handling
class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code?: string
  ) {
    super(message);
  }
}

// Middleware pattern for auth
const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const user = await verifyJwtToken(token);
    req.user = user;
    next();
  } catch (error) {
    next(new ApiError(401, 'Unauthorized'));
  }
};
```

## 🎨 Frontend Architecture

### **Component Structure**
```
├── src/
│   ├── components/         # Reusable components
│   │   ├── ui/            # Basic UI components
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── Modal.tsx
│   │   ├── layout/        # Layout components
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Footer.tsx
│   │   ├── auth/          # Authentication
│   │   │   ├── LoginForm.tsx
│   │   │   └── RegisterForm.tsx
│   │   ├── studio/        # AI generation
│   │   │   ├── PromptInput.tsx
│   │   │   ├── GenerationProgress.tsx
│   │   │   └── ResultGallery.tsx
│   │   ├── comics/        # Comics builder
│   │   │   ├── PanelEditor.tsx
│   │   │   ├── SpeechBubble.tsx
│   │   │   └── ComicExport.tsx
│   │   └── admin/         # Admin panel
│   │       ├── UserManagement.tsx
│   │       ├── SystemMetrics.tsx
│   │       └── ContentModeration.tsx
│   ├── pages/             # Page components
│   │   ├── Home.tsx
│   │   ├── Studio.tsx
│   │   ├── Gallery.tsx
│   │   └── Admin.tsx
│   ├── hooks/             # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useWebSocket.ts
│   │   └── useApiQuery.ts
│   ├── services/          # API services
│   │   ├── api.service.ts
│   │   ├── auth.service.ts
│   │   └── websocket.service.ts
│   ├── stores/            # State management
│   │   ├── auth.store.ts
│   │   ├── ui.store.ts
│   │   └── jobs.store.ts
│   ├── utils/             # Utility functions
│   │   ├── format.utils.ts
│   │   ├── validation.utils.ts
│   │   └── storage.utils.ts
│   └── types/             # TypeScript types
│       ├── api.types.ts
│       ├── user.types.ts
│       └── media.types.ts
```

### **State Management with Zustand**
```typescript
// Auth Store
interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
  refreshToken: () => Promise<void>;
}

// Jobs Store for AI generation
interface JobsState {
  activeJobs: Job[];
  completedJobs: Job[];
  addJob: (job: Job) => void;
  updateJobProgress: (jobId: string, progress: number) => void;
  completeJob: (jobId: string, result: JobResult) => void;
}
```

## 🤖 AI Worker Architecture

### **Python Worker Structure**
```
├── ai-worker/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py            # FastAPI server
│   │   ├── worker.py          # BullMQ job processor
│   │   ├── models/            # AI model managers
│   │   │   ├── image_generator.py
│   │   │   ├── video_generator.py
│   │   │   └── upscaler.py
│   │   ├── workflows/         # ComfyUI workflows
│   │   │   ├── text_to_image.json
│   │   │   ├── image_to_video.json
│   │   │   └── comic_generation.json
│   │   ├── utils/
│   │   │   ├── progress.py
│   │   │   ├── storage.py
│   │   │   └── validation.py
│   │   └── config/
│   │       └── settings.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
```

### **AI Model Integration**
```python
# Image Generation Pipeline
class ImageGenerator:
    def __init__(self):
        self.comfy_client = ComfyUIClient()
        self.models = {
            'sdxl': 'stabilityai/stable-diffusion-xl-base-1.0',
            'flux': 'black-forest-labs/flux.1-dev',
            'ip_adapter': 'h94/IP-Adapter'
        }
    
    async def generate_image(self, prompt: str, options: dict) -> dict:
        workflow = self.load_workflow('text_to_image.json')
        workflow['inputs']['prompt'] = prompt
        
        # Submit to ComfyUI
        job_id = await self.comfy_client.submit_workflow(workflow)
        
        # Monitor progress
        async for progress in self.comfy_client.monitor_progress(job_id):
            await self.update_progress(progress)
        
        # Get result
        result = await self.comfy_client.get_result(job_id)
        return result
```

## 🔄 Job Queue Architecture

### **BullMQ Integration**
```typescript
// Job Queue Setup
const jobQueue = new Queue('ai-generation', {
  connection: {
    host: 'redis',
    port: 6379,
  },
  defaultJobOptions: {
    removeOnComplete: 100,
    removeOnFail: 50,
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 2000,
    },
  },
});

// Job Types
interface ImageJobData {
  userId: string;
  prompt: string;
  model: 'sdxl' | 'flux';
  dimensions: { width: number; height: number };
  steps: number;
  guidance: number;
}

// Job Processing
jobQueue.process('image-generation', async (job) => {
  const { userId, prompt, ...options } = job.data;
  
  // Update progress
  await job.updateProgress(10);
  
  // Generate image
  const result = await aiWorker.generateImage(prompt, options);
  
  // Save to storage
  const mediaUrl = await storage.save(result.image, userId);
  
  // Update progress
  await job.updateProgress(100);
  
  return { mediaUrl, metadata: result.metadata };
});
```

## 🔒 Security Architecture

### **Authentication & Authorization**
```typescript
// JWT Token Structure
interface JwtPayload {
  userId: string;
  role: UserRole;
  permissions: string[];
  iat: number;
  exp: number;
}

// Permission-based middleware
const requirePermission = (permission: string) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = req.user;
    if (!user.permissions.includes(permission)) {
      throw new ApiError(403, 'Insufficient permissions');
    }
    next();
  };
};

// Rate limiting strategy
const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: (req) => {
    // Different limits based on user role
    switch (req.user?.role) {
      case UserRole.SUPER_ADMIN: return 10000;
      case UserRole.ADMIN: return 5000;
      case UserRole.CREATOR: return 2000;
      case UserRole.USER: return 1000;
      default: return 100; // Guest
    }
  },
  standardHeaders: true,
  legacyHeaders: false,
});
```

### **Data Protection**
- **Encryption**: AES-256 for sensitive data at rest
- **HTTPS**: TLS 1.3 with HSTS headers
- **Input Validation**: Zod schemas for all inputs
- **SQL Injection**: Parameterized queries with Prisma
- **XSS Protection**: Content Security Policy headers
- **File Security**: Virus scanning, MIME validation

## 📊 Monitoring Architecture

### **Observability Stack**
```yaml
# Monitoring Services
monitoring:
  prometheus:
    image: prom/prometheus
    config: ./prometheus.yml
    
  grafana:
    image: grafana/grafana
    dashboards: ./grafana/dashboards/
    
  loki:
    image: grafana/loki
    config: ./loki-config.yml
    
  promtail:
    image: grafana/promtail
    config: ./promtail-config.yml
```

### **Metrics Collection**
- **Application Metrics**: Request duration, error rates
- **Business Metrics**: User registrations, AI generations
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Custom Metrics**: AI job queue length, generation success rates

---

This architecture provides a scalable, secure, and maintainable foundation for the AI Media & Comics Website with clear separation of concerns and modern best practices.
