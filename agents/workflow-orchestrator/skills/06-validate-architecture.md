# Skill: Validate Architecture

**Purpose:** Validar que el código cumple con reglas de arquitectura (CAS - Compliance Architecture System)
**Duration:** 2-3 minutos
**Mode:** Advisory (warnings, no bloquea)
**Critical:** Moderado

---

## 🎯 Objetivo

Verificar que el código nuevo cumple con:
- Convenciones de naming
- Estructura de capas (Controllers → Services → Repositories)
- No circular dependencies
- Import order correcto
- Reglas personalizadas del proyecto

**Modo Advisory:** Solo genera warnings, NO bloquea el workflow (a diferencia de regression que SÍ bloquea).

---

## 📋 Proceso

### 1. Detectar Configuración del Proyecto

Buscar archivos de configuración CAS:
- `.arch-rules.ts` (reglas ts-arch)
- `.eslintrc-arch.js` (reglas ESLint)
- `.workflow-config.json` (config personalizada)

### 2. Validar Layering

**Regla:** Routers solo pueden importar Services, NO directamente repositories/SQLAlchemy session

```python
# VIOLATION
# backend/app/routers/user_router.py
from app.db.session import get_db  # Direct DB access in router - NOT ALLOWED

# CORRECT
from app.services.user_service import UserService
from app.dependencies import get_user_service
```

**Verificacion:**
```bash
# Buscar imports de session/db en routers
grep -r "from.*db\." backend/app/routers/
grep -r "from.*session" backend/app/routers/
```

### 3. Validar Naming Conventions

**Reglas:**
- Files: snake_case (`user_service.py`)
- Classes: PascalCase (`UserService`)
- Functions: snake_case (`get_user_by_id`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`)

**Verificacion:**
```bash
# Buscar archivos que no sigan snake_case en backend
find backend/app -name "*[A-Z]*.py"
```

### 4. Detectar Circular Dependencies

```bash
# Usar madge o similar para detectar ciclos
npx madge --circular backend/src/
```

### 5. Validar Import Order

**Orden esperado:**
1. Standard library (`os`, `json`, `pathlib`)
2. Third-party (`fastapi`, `sqlalchemy`, `pydantic`)
3. Local application (`app.services`, `app.repositories`)
4. Relative (`.`, `..`)

### 6. Validar Estructura de Archivos

**Estructura esperada:**
```
backend/src/
├── controllers/     # HTTP handlers
├── services/        # Business logic
├── repositories/    # Data access
├── middleware/      # Express middleware
├── routes/          # Route definitions
├── types/           # TypeScript types
└── utils/           # Helpers
```

**Validar:** No hay archivos fuera de estas carpetas

---

## 📊 Output Esperado

### Si TODO cumple (✅)

```
🏛️  Validación de Arquitectura (CAS)

Verificando reglas del proyecto...

✅ Layering: Cumple
   Controllers → Services → Repositories

✅ Naming conventions: Cumple
   245 archivos verificados

✅ Circular dependencies: Ninguna detectada

✅ Import order: Cumple
   ESLint rules passed

✅ File structure: Cumple
   Todos los archivos en carpetas correctas

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 CAS Validation: PASSED
0 violations, 0 warnings

✅ Arquitectura limpia y consistente
```

### Si HAY VIOLACIONES (⚠️)

```
🏛️  Validación de Arquitectura (CAS)

Verificando reglas del proyecto...

✅ Layering: Cumple

⚠️  Naming conventions: 2 violations
   - notification_Service.py (debe ser notification_service.py)
   - NotificationUtils.py (debe ser notification_utils.py)

Circular dependencies: Ninguna

Import order: 3 violations
   - notification_router.py:5 (external after internal)
   - notification_service.py:12 (relative before external)
   - useNotifications.tsx:8 (wrong order, frontend)

File organization: 1 violation
   - app/notification_helper.py (debe estar en app/utils/)

---

CAS Validation: PASSED with warnings

6 violations detectadas (modo advisory)
   - 2 naming
   - 3 import order
   - 1 file organization

Recomendaciones:
1. Renombrar archivos a snake_case
2. Reordenar imports (puedes usar: ruff check --fix)
3. Mover notification_helper.py a app/utils/

ℹ️  Modo Advisory: No bloquea el workflow
   Puedes continuar, pero considera arreglar estos issues
```

---

## 🔧 Reglas Configurables

El proyecto puede definir reglas personalizadas en `.arch-rules.py`:

```python
# .arch-rules.py
rules = {
    "layering": {
        "routers": {
            "can_import": ["services", "schemas", "dependencies"],
            "cannot_import": ["repositories", "db.session"]
        },
        "services": {
            "can_import": ["repositories", "schemas", "utils"],
            "cannot_import": ["routers", "endpoints"]
        }
    },
    "naming": {
        "files": "snake_case",
        "classes": "PascalCase",
        "functions": "snake_case"
    },
    "max_file_size": 300,  # lines
    "max_complexity": 10,
}
```

---

## Categorias de Violaciones

### Critical (Bloquean - pero NO en modo advisory)
- Circular dependencies
- Import de db.session en routers (debe ir via Depends)
- Archivos en lugares incorrectos

### Warning (Solo advierten)
- Naming conventions
- Import order
- Archivos muy largos (>300 LOC)
- Complejidad alta

### Info (Sugerencias)
- Falta documentación
- Tests con baja cobertura
- TODOs en código

---

## 📝 Reporte Generado

Crear `.checkpoints/06-architecture-validation.md`:

```markdown
# Architecture Validation Report

**Timestamp:** 2026-03-08 11:15:00
**Mode:** Advisory

## Summary
- Violations: 6
- Warnings: 3
- Info: 2

## Violations Detail

### 1. Naming Convention
**File:** backend/app/services/notification_Service.py
**Rule:** File names must be snake_case
**Current:** notification_Service.py
**Expected:** notification_service.py
**Fix:** Rename file

### 2. Import Order
**File:** backend/app/routers/notification_router.py
**Line:** 5
**Rule:** Third-party imports must come before local imports
**Current:**
```python
from app.services.notification_service import NotificationService
from fastapi import APIRouter  # <- Wrong order
```
**Expected:**
```python
from fastapi import APIRouter
from app.services.notification_service import NotificationService
```
**Fix:** Reorder imports (auto-fixable with ruff)

[... more violations ...]

## Recommendations
1. Run `ruff check --fix` to auto-fix import order
2. Rename files to snake_case
3. Consider splitting large files (notification_service.py: 315 LOC)

## Next Steps
⚠️  Modo Advisory - Workflow NO bloqueado
   Puedes continuar, pero se recomienda arreglar estas issues
```

---

## 💡 Integration con Workflow

Esta skill se ejecuta OPCIONALMENTE en FASE 4:

```
FASE 4: QA + Regression
  ├─ 4.1: Tests nuevos
  ├─ 4.2: Regression (CRÍTICO - bloquea)
  ├─ 4.3: Visual tests
  └─ 4.4: Architecture validation (ADVISORY - no bloquea)
```

**Diferencia con Regression:**
- Regression: ❌ Bloquea si falla
- Architecture: ⚠️  Solo advierte, no bloquea

---

**Duración estimada:** 2-3 minutos
**Mode:** Advisory (warnings only)
