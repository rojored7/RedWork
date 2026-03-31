# 🏗️ INFRASTRUCTURE DEPLOYMENT VALIDATION PROTOCOL

## ⚠️ MANDATORY VALIDATION CHECKLIST

**This protocol MUST be followed by the Infrastructure-Development-Agent on EVERY deployment.**
**DO NOT report success until ALL items are validated and passing.**

---

## 📋 PRE-DEPLOYMENT CHECKS

### 1. Docker Environment
- [ ] Docker Desktop is running
- [ ] Docker compose version verified (≥ 2.0)
- [ ] No port conflicts detected
- [ ] Sufficient disk space available (min 10GB free)
- [ ] Network driver available

---

## 🚀 DEPLOYMENT PHASE

### 2. Container Deployment
For EACH service in docker-compose.yml:

#### PostgreSQL Database
- [ ] Container started successfully
- [ ] Port 15432 mapped and accessible
- [ ] Health check passing (pg_isready)
- [ ] Database initialized with schemas
- [ ] Test connection: `psql -h localhost -p 15432 -U taskadmin -d taskmanager -c '\dt'`
- [ ] All expected tables present

#### Redis Cache
- [ ] Container started successfully
- [ ] Port 16379 mapped and accessible
- [ ] Health check passing (redis-cli ping)
- [ ] Test connection: `redis-cli -h localhost -p 16379 ping`
- [ ] Response: PONG

#### Backend (FastAPI)
- [ ] Container started successfully
- [ ] Port 18000 mapped and accessible
- [ ] **CRITICAL**: Dependencies installed (`pip list` shows all requirements)
- [ ] Database connection successful
- [ ] Redis connection successful
- [ ] Health endpoint responds: `curl http://localhost:18000/health`
- [ ] API docs accessible: `curl http://localhost:18000/docs`
- [ ] **NO compilation errors in logs**
- [ ] **NO import errors in logs**
- [ ] All API routes registered and working

#### Frontend (React + Vite)
- [ ] Container started successfully
- [ ] Port 15173 mapped and accessible
- [ ] **CRITICAL**: `npm install` executed successfully inside container
- [ ] **CRITICAL**: All node_modules present in container: `docker exec taskmanager_frontend ls /app/node_modules | wc -l` > 50
- [ ] **CRITICAL**: Vite dev server started without errors
- [ ] **NO compilation errors** (check: `docker logs taskmanager_frontend`)
- [ ] **NO missing dependencies errors**
- [ ] Application loads in browser: `curl -s http://localhost:15173 | grep "root"`
- [ ] **VISUAL VERIFICATION**: Open http://localhost:15173 - page must load, NO error overlay
- [ ] React app renders (not just HTML scaffold)
- [ ] Console has no errors (check browser dev tools)

---

## 🔍 POST-DEPLOYMENT VALIDATION

### 3. End-to-End Service Verification

#### Backend → Database Integration
```bash
# Test database query through API
curl -X GET http://localhost:18000/api/v1/health | jq '.database.status'
# Expected: "connected"
```

#### Backend → Redis Integration
```bash
# Test Redis through API
curl -X GET http://localhost:18000/api/v1/health | jq '.cache.status'
# Expected: "connected"
```

#### Frontend → Backend Integration
```bash
# Test API connectivity from frontend
# Check browser console or network tab - API calls should succeed
```

### 4. Application Functionality Checks

#### Authentication Flow
- [ ] Login page loads without errors
- [ ] Login form is visible and interactive
- [ ] Form inputs are accessible (email, password)
- [ ] Submit button present and clickable
- [ ] **Test actual login**: POST to `/api/v1/auth/login` works
- [ ] JWT token generated successfully

#### Core Features
- [ ] Dashboard page accessible (after auth)
- [ ] Tasks page loads
- [ ] Projects page loads
- [ ] All routes defined in router work

---

## 🐛 ERROR DETECTION

### 5. Log Analysis (MANDATORY)

For EACH service, check logs for errors:

```bash
# Frontend logs - MUST be clean
docker logs taskmanager_frontend --tail 100

# Check for:
❌ "Failed to resolve import"
❌ "Module not found"
❌ "Cannot find module"
❌ "ENOENT"
❌ "ERR_MODULE_NOT_FOUND"
❌ Any red error messages

# Backend logs - MUST be clean
docker logs taskmanager_backend --tail 100

# Check for:
❌ Import errors
❌ Module not found
❌ Connection refused
❌ Any uncaught exceptions

# Database logs
docker logs taskmanager_postgres --tail 50
# Should show successful initialization

# Redis logs
docker logs taskmanager_redis --tail 50
# Should show "Ready to accept connections"
```

---

## ✅ SUCCESS CRITERIA

**ALL of the following MUST be true before reporting deployment success:**

1. ✅ All containers running and healthy
2. ✅ No compilation errors in any service
3. ✅ No missing dependency errors
4. ✅ Frontend loads in browser WITHOUT error overlay
5. ✅ Backend API responds to health checks
6. ✅ Database accepts connections
7. ✅ Redis accepts connections
8. ✅ Frontend can communicate with backend
9. ✅ At least one successful API call works (e.g., health check)
10. ✅ Application is usable (not just containers running)

---

## 🔧 COMMON FIXES REQUIRED

If validation fails, fix BEFORE reporting:

### Frontend Issues
```bash
# Install dependencies in container
docker exec taskmanager_frontend npm install

# Rebuild if needed
docker-compose -f infrastructure/docker-compose.yml restart frontend

# Verify fix
docker exec taskmanager_frontend ls /app/node_modules | wc -l
# Should show > 50 packages
```

### Backend Issues
```bash
# Install dependencies in container
docker exec taskmanager_backend pip install -r requirements.txt

# Run migrations
docker exec taskmanager_backend alembic upgrade head

# Restart
docker-compose -f infrastructure/docker-compose.yml restart backend
```

### Database Issues
```bash
# Recreate database
docker-compose -f infrastructure/docker-compose.yml down
docker volume rm taskmanager_postgres_data
docker-compose -f infrastructure/docker-compose.yml up -d postgres
# Wait for initialization
```

---

## 📊 REPORTING FORMAT

When reporting deployment status, use this format:

```
## DEPLOYMENT STATUS

✅ VALIDATED - All checks passing
or
❌ FAILED - Issues found (with details)

### Infrastructure Health
- PostgreSQL: ✅/❌ (details)
- Redis: ✅/❌ (details)
- Backend: ✅/❌ (details)
- Frontend: ✅/❌ (details)

### Critical Validations
- [ ] Frontend compiles without errors
- [ ] Frontend loads in browser
- [ ] Backend API responds
- [ ] Database connectivity confirmed
- [ ] No error logs detected

### Issues Found
(List any issues with exact error messages and commands to reproduce)

### Actions Taken
(List all fixes applied)

### Final Verification
- Browser test: http://localhost:15173 - ✅/❌
- API test: http://localhost:18000/health - ✅/❌
- Database test: psql connection - ✅/❌
```

---

## 🚨 NEVER DO THIS

❌ Report success with "despite health check status" or "functional despite..."
❌ Skip dependency installation steps
❌ Assume logs are fine without reading them
❌ Report "running" as equivalent to "working"
❌ Skip browser verification
❌ Trust health checks alone - validate manually

---

## ✨ ALWAYS DO THIS

✅ Read ALL service logs
✅ Test in browser/curl, not just container status
✅ Verify dependencies are installed
✅ Fix ALL errors before reporting
✅ Provide evidence of successful tests
✅ Include screenshots if errors persist
✅ Give exact reproduction steps for any issues

---

**REMEMBER: "Running" ≠ "Working"**
**A container can be "up" but the application can be broken.**
**VALIDATE FUNCTIONALITY, not just container status.**
