# Scripts de Validación - Plan de Desarrollo Sprint

Este directorio contiene scripts para validar la funcionalidad del sistema en cada fase del sprint.

## Scripts Disponibles

### 1. health-check (.sh / .bat)
**Propósito**: Verificar que todos los servicios están UP y respondiendo

**Uso**:
```bash
# Linux/Mac/Git Bash
./scripts/health-check.sh

# Windows CMD/PowerShell
scripts\health-check.bat
```

**Checks**:
- ✅ Backend health endpoint
- ✅ Database connection
- ✅ Redis connection
- ✅ Frontend serving

---

### 2. smoke-test-backend (.sh / .bat)
**Propósito**: Validar funcionalidad básica del backend

**Uso**:
```bash
# Linux/Mac/Git Bash
./scripts/smoke-test-backend.sh

# Windows CMD/PowerShell
scripts\smoke-test-backend.bat
```

**Checks**:
- ✅ Health check responde con status "ok"
- ✅ Database connection activa
- ✅ Redis connection activa

---

### 3. smoke-test-frontend (.sh / .bat)
**Propósito**: Validar que frontend carga correctamente

**Uso**:
```bash
# Linux/Mac/Git Bash
./scripts/smoke-test-frontend.sh

# Windows CMD/PowerShell
scripts\smoke-test-frontend.bat
```

**Checks**:
- ✅ Frontend sirve HTML
- ✅ JavaScript bundles cargan
- ✅ Build artifacts existen

---

### 4. smoke-test-api.sh
**Propósito**: Validar endpoints de API funcionan correctamente

**Uso**:
```bash
# Solo disponible en Linux/Mac/Git Bash
./scripts/smoke-test-api.sh
```

**Checks**:
- ✅ POST /auth/register funciona
- ✅ POST /auth/login funciona
- ✅ Protected endpoints requieren autenticación

**Nota**: Este script requiere Bash por uso de variables. En Windows usar Git Bash o WSL.

---

### 5. integration-test.sh
**Propósito**: Ejecutar todos los integration tests

**Uso**:
```bash
# Solo disponible en Linux/Mac/Git Bash/WSL
./scripts/integration-test.sh
```

**Fases**:
1. Levantar servicios de test (docker-compose.test.yml)
2. Ejecutar integration tests backend
3. Ejecutar E2E tests
4. Limpiar servicios

---

### 6. validate-wave.sh
**Propósito**: Validar completado de un wave específico

**Uso**:
```bash
# Solo disponible en Linux/Mac/Git Bash/WSL
./scripts/validate-wave.sh <wave_number>

# Ejemplo:
./scripts/validate-wave.sh 3  # Valida Wave 3 (Application Layer)
```

**Waves disponibles**:
- Wave 1: Infrastructure
- Wave 2: Domain Layer
- Wave 3: Application Layer
- Wave 4: API Layer
- Wave 5: Frontend

---

## Prerrequisitos

### Para scripts .sh (Linux/Mac/Git Bash/WSL):
- Bash shell
- curl
- docker & docker-compose
- npm

### Para scripts .bat (Windows):
- Windows CMD o PowerShell
- curl (incluido en Windows 10+)
- docker & docker-compose
- npm

---

## Cuándo Usar Cada Script

### Durante Desarrollo

**Al finalizar Wave 1 (Infrastructure)**:
```bash
./scripts/health-check.sh
```

**Al finalizar Wave 3 (Application Layer)**:
```bash
./scripts/smoke-test-backend.sh
```

**Al finalizar Wave 4 (API Layer)**:
```bash
./scripts/smoke-test-api.sh
```

**Al finalizar Wave 5 (Frontend)**:
```bash
./scripts/smoke-test-frontend.sh
```

**Al finalizar Sprint**:
```bash
# Todos los smoke tests
./scripts/health-check.sh
./scripts/smoke-test-backend.sh
./scripts/smoke-test-frontend.sh
./scripts/smoke-test-api.sh

# Integration tests
./scripts/integration-test.sh
```

---

## Validación Completa de Wave

Para validar que un wave está 100% completo:

```bash
# Wave 1
./scripts/validate-wave.sh 1

# Wave 2
./scripts/validate-wave.sh 2

# Wave 3
./scripts/validate-wave.sh 3

# Wave 4
./scripts/validate-wave.sh 4

# Wave 5
./scripts/validate-wave.sh 5
```

---

## Troubleshooting

### Error: "Permission denied"
```bash
# Dar permisos de ejecución (Linux/Mac)
chmod +x scripts/*.sh
```

### Error: "curl: command not found"
```bash
# Windows: curl viene incluido en Windows 10+
# Linux: sudo apt-get install curl
# Mac: brew install curl
```

### Error: "docker-compose: command not found"
```bash
# Instalar Docker Desktop que incluye docker-compose
```

### Scripts .sh no funcionan en Windows CMD
- **Solución 1**: Usar scripts .bat equivalentes
- **Solución 2**: Usar Git Bash (viene con Git for Windows)
- **Solución 3**: Usar WSL (Windows Subsystem for Linux)

---

## Integración con CI/CD

Estos scripts pueden ser usados en pipelines CI/CD:

```yaml
# Ejemplo GitHub Actions
- name: Health Check
  run: ./scripts/health-check.sh

- name: Backend Smoke Tests
  run: ./scripts/smoke-test-backend.sh

- name: Integration Tests
  run: ./scripts/integration-test.sh
```

---

## Contribuir

Al añadir nuevos scripts:
1. Crear versión .sh para Linux/Mac
2. Crear versión .bat para Windows
3. Documentar en este README
4. Añadir ejemplos de uso
5. Incluir en validate-wave.sh si corresponde

---

**Generado**: 2026-03-23
**Versión**: 1.0
**Parte del**: Plan de Desarrollo Sprint - DDD + TDD + Validación Funcional
