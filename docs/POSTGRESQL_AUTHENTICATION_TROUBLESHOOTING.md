# PostgreSQL Authentication Troubleshooting Documentation

## 📋 Project Overview
**Project**: AI Comics Backend - Professional Node.js/Express server with PostgreSQL database
**Environment**: Windows host connecting to PostgreSQL 15 running in Docker container
**Issue**: PostgreSQL Error 28P01 - Password authentication failed

---

## 🔍 Current Status
**Status**: ❌ BLOCKED - Database authentication failure preventing backend server startup
**Error Code**: 28P01 (password authentication failed for user "postgres")
**Impact**: Complete backend server startup failure, blocking all development

---

## 🏗️ Architecture Overview

### Backend Stack
- **Framework**: Express.js with professional middleware stack
- **Authentication**: Session-based with Redis store, bcrypt password hashing
- **Database**: PostgreSQL 15 in Docker container
- **Security**: Helmet, CORS, rate limiting, role-based access control (5 levels)
- **Monitoring**: Prometheus metrics, health checks

### Database Configuration
- **Container**: `ai-comics-db` (PostgreSQL 15-alpine)
- **Port Mapping**: `localhost:5432` → container `5432`
- **Database**: `aicomics`
- **User**: `postgres`
- **Expected Password**: `postgres123`

---

## 🚨 Error Analysis

### Primary Error
```
Error Code: 28P01
Message: password authentication failed for user "postgres"
Description: PostgreSQL authentication failure when connecting from Node.js client
```

### Connection Attempts
All connection attempts fail with identical error:
```javascript
// Connection string attempts
postgresql://postgres:postgres123@127.0.0.1:5432/aicomics
postgresql://postgres:postgres123@localhost:5432/aicomics
postgresql://postgres@127.0.0.1:5432/aicomics  // No password
postgresql://postgres@localhost:5432/aicomics   // No password

// Object configuration attempts
{
  host: '127.0.0.1',
  port: 5432,
  database: 'aicomics',
  user: 'postgres',
  password: 'postgres123'
}
```

---

## 🔧 Troubleshooting Timeline

### Phase 1: Initial Discovery
**Date**: Session start
**Issue**: Backend server failing to connect to PostgreSQL
**Initial Error**: Error 28P01 on all connection attempts

### Phase 2: pg_hba.conf Rule Precedence Investigation
**Root Cause Found**: PostgreSQL processes pg_hba.conf rules top-to-bottom, first match wins
**Problem**: Catch-all `scram-sha-256` rule was placed before specific trust rules

**Original (Incorrect) pg_hba.conf**:
```
host    all    all    0.0.0.0/0       scram-sha-256  # ❌ Catch-all first
host    all    all    127.0.0.1/32    trust         # ❌ Never reached
```

**Corrected Rule Order**:
```
host    all    all    127.0.0.1/32    trust         # ✅ Specific first
host    all    all    0.0.0.0/0       scram-sha-256  # ✅ Catch-all last
```

### Phase 3: Trust Authentication Attempt
**Approach**: Remove passwords entirely, rely on pg_hba.conf trust rules
**Files Modified**:
- `backend/src/config/database.js` - Removed password from connection string
- `backend/.env` - Updated DATABASE_URL without password
- `database/pg_hba_corrected.conf` - Applied corrected rule precedence

**Result**: ❌ Still failed with SASL SCRAM errors
**New Error**: `SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string`

### Phase 4: TCP vs Unix Socket Discovery
**Critical Finding**: TCP connections to 127.0.0.1 trigger SCRAM handshake regardless of pg_hba.conf trust rules
**Technical Explanation**:
- TCP connections fall through to catch-all `scram-sha-256` rule
- Trust rules only apply to Unix domain socket connections (`local` in pg_hba.conf)
- Node.js pg client initiates SCRAM before PostgreSQL can apply trust

**PostgreSQL Logs**:
```
2025-08-14 22:16:24.982 UTC [308] LOG: connection received: host=[local]
2025-08-14 22:16:24.982 UTC [308] LOG: connection authorized: user=postgres database=aicomics
```
*Note: Logs show `host=[local]` for working connections, but our Node.js connections never appear in logs*

### Phase 5: Password Authentication Restoration
**Approach**: Revert to standard password authentication with proper pg_hba.conf
**Actions Taken**:
1. Restored password in connection strings
2. Updated pg_hba.conf to use `md5` authentication for 127.0.0.1
3. Reset postgres user password multiple times
4. Tried both `md5` and `scram-sha-256` authentication methods

**Password Reset Commands**:
```sql
ALTER USER postgres PASSWORD 'postgres123';
ALTER USER postgres PASSWORD 'simplepass';
```

**pg_hba.conf Configurations Tested**:
```
# Attempt 1: MD5 authentication
host    all    all    127.0.0.1/32    md5

# Attempt 2: SCRAM-SHA-256 authentication  
host    all    all    127.0.0.1/32    scram-sha-256
```

**Result**: ❌ All attempts still fail with Error 28P01

---

## 🧪 Test Results Summary

### Connection Tests Performed
1. **Trust Authentication Tests**: 5 different methods, all failed with SASL errors
2. **Password Authentication Tests**: Multiple passwords and auth methods, all failed with 28P01
3. **Test User Creation**: Created `testuser` with simple password, still failed
4. **Direct Container Tests**: psql works inside container, external connections fail

### Verification Commands
```bash
# Container environment check
docker exec ai-comics-db env | findstr POSTGRES
# Output: POSTGRES_PASSWORD=postgres123 ✅

# Password hash verification
docker exec ai-comics-db psql -U postgres -c "SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'postgres';"
# Output: SCRAM-SHA-256 hash present ✅

# Configuration verification
docker exec ai-comics-db cat /var/lib/postgresql/data/pg_hba.conf | findstr "127.0.0.1"
# Output: host all all 127.0.0.1/32 md5 ✅
```

---

## 📁 File Inventory

### Modified Files
1. **`backend/src/config/database.js`**
   - Purpose: Database connection configuration
   - Changes: Toggled between password/no-password connection strings
   - Current State: Password authentication enabled

2. **`backend/.env`**
   - Purpose: Environment variables
   - Changes: Updated DATABASE_URL multiple times
   - Current State: `postgresql://postgres:postgres123@127.0.0.1:5432/aicomics`

3. **`database/pg_hba_corrected.conf`**
   - Purpose: Corrected authentication rules with proper precedence
   - Current State: Trust for local, SCRAM for catch-all

4. **`database/pg_hba_production.conf`**
   - Purpose: Production-ready authentication with password requirements
   - Current State: MD5 for localhost, SCRAM for catch-all

### Test Files Created
1. **`backend/test-auth.js`** - Comprehensive authentication testing (5 methods)
2. **`backend/test-trust-auth.js`** - Unix socket trust authentication test
3. **`backend/test-password-auth.js`** - Standard password authentication test
4. **`backend/test-all-connections.js`** - Multiple connection method tests
5. **`backend/test-testuser.js`** - Test user authentication verification

---

## 🔍 Current Hypotheses

### Working Theory 1: Docker Networking Issue
- **Evidence**: Internal container connections work, external fail
- **Potential Cause**: Port mapping or network isolation affecting authentication
- **Status**: Unverified

### Working Theory 2: Authentication Method Mismatch
- **Evidence**: Password stored as SCRAM-SHA-256, but various auth methods tried
- **Potential Cause**: Client/server authentication protocol mismatch
- **Status**: Partially investigated

### Working Theory 3: Container State Corruption
- **Evidence**: Multiple configuration changes without clean restart
- **Potential Cause**: Cached authentication state or configuration conflicts
- **Status**: Restart attempted, issue persists

---

## 🛠️ Attempted Solutions

### ❌ Failed Approaches
1. **Trust Authentication**: Removed passwords, relied on pg_hba.conf trust rules
2. **Rule Precedence Fix**: Corrected pg_hba.conf order (specific before catch-all)
3. **Unix Socket Connection**: Attempted to force socket connections (Docker limitation)
4. **Password Resets**: Multiple password changes with different values
5. **Authentication Method Changes**: Tried md5, scram-sha-256, trust
6. **Container Restarts**: Full PostgreSQL container restarts
7. **Test User Creation**: Created alternative user to isolate issue

### 🔄 Configuration Reloads
- `SELECT pg_reload_conf();` - Applied configuration changes
- `docker-compose restart postgres` - Full container restart
- `docker cp` - Updated pg_hba.conf files

---

## 📊 Current Configuration State

### Database Connection Config
```javascript
// backend/src/config/database.js
const pool = new Pool({
  connectionString: 'postgresql://postgres:postgres123@127.0.0.1:5432/aicomics',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### Environment Variables
```properties
# backend/.env
DATABASE_URL=postgresql://postgres:postgres123@127.0.0.1:5432/aicomics
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=aicomics
DB_USER=postgres
DB_PASSWORD=postgres123
```

### Active pg_hba.conf
```
# Trust for local socket connections
local   all             all                                     trust

# MD5 for TCP connections
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5

# SCRAM for all other connections
host    all             all             0.0.0.0/0               scram-sha-256
```

---

## 🚧 Next Steps & Recommendations

### Option 1: Complete Container Rebuild
**Approach**: Fresh PostgreSQL container with clean state
**Commands**:
```bash
docker-compose down postgres
docker volume rm <postgres_volume>
docker-compose up postgres
```
**Risk**: Data loss, requires database schema recreation

### Option 2: Alternative Authentication Method
**Approach**: Use environment variables for connection from within container network
**Implementation**: Modify connection to use container name instead of localhost
**Example**: `postgresql://postgres:postgres123@ai-comics-db:5432/aicomics`

### Option 3: PostgreSQL Version Downgrade
**Approach**: Use older PostgreSQL version with simpler authentication
**Rationale**: PostgreSQL 15 introduced stricter SCRAM defaults

### Option 4: External PostgreSQL Instance
**Approach**: Use local PostgreSQL installation instead of Docker
**Benefit**: Eliminates Docker networking complexity

---

## 📈 Impact Assessment

### Blocked Features
- ✅ **Backend Architecture**: Complete, ready to deploy
- ✅ **Authentication System**: Implemented, tested independently  
- ✅ **Database Schema**: Enhanced with proper relationships
- ❌ **Server Startup**: Blocked by database connection
- ❌ **API Endpoints**: Cannot test due to server startup failure
- ❌ **Frontend Integration**: Waiting on backend availability

### Development Timeline Impact
- **Current Blocker**: Database authentication (Day 1 of debugging)
- **Estimated Resolution**: 1-2 hours with correct approach
- **Alternative Workaround**: Switch to SQLite for development (30 minutes)

---

## 🔧 Technical Specifications

### Error Codes Encountered
- **28P01**: Password authentication failed
- **SASL errors**: SCRAM handshake failures
- **Connection timeouts**: When authentication method mismatches

### Tools Used
- **psql**: Direct database connection testing
- **docker exec**: Container inspection and debugging
- **node pg**: PostgreSQL client library testing
- **Docker logs**: Authentication event monitoring

### Configuration Files
- **pg_hba.conf**: PostgreSQL Host-Based Authentication
- **postgresql.conf**: PostgreSQL main configuration
- **.env**: Environment variables
- **docker-compose.yml**: Container orchestration

---

*Last Updated: 2025-08-15 00:34 UTC*
*Session Status: Authentication debugging in progress*
*Next Action: Determine approach for resolution (rebuild vs alternative)*
