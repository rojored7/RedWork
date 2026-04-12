# Skill: Run Regression Testing

**Purpose:** Ejecutar TODOS los tests y detectar si algo se rompió
**Duration:** 5-10 minutos
**Critical:** ⚠️⚠️⚠️ EXTREMADAMENTE CRÍTICO - Previene bugs en producción

---

## 🎯 Objetivo

Ejecutar la suite COMPLETA de tests (todos los existentes + los nuevos) y comparar con el baseline capturado previamente.

**Meta:** Garantizar que NINGÚN test viejo se rompió con los cambios nuevos.

---

## 🚨 Reglas Inquebrantables

1. **SIEMPRE** comparar con baseline (debe existir `.baselines/latest.json`)
2. Si **CUALQUIER** test viejo falla → **BLOQUEAR workflow completo**
3. Generar reporte detallado de qué falló y por qué
4. NO permitir continuar hasta que se arregle

---

## 📋 Proceso

### 1. Verificar Baseline Existe

```bash
# Verificar que existe baseline
if [ ! -f ".baselines/latest.json" ]; then
  echo "❌ ERROR: No hay baseline capturado"
  echo "   Ejecuta primero: skill 01-capture-baseline"
  exit 1
fi
```

### 2. Cargar Datos del Baseline

Leer `.baselines/latest.json` y extraer:
- Total de tests: `tests.total`
- Tests passed: `tests.passed`
- Tests failed: `tests.failed`

### 3. Ejecutar Suite Completa ACTUAL

#### Backend Tests (pytest)
```bash
cd backend
python -m pytest tests/ -v --tb=short --json-report --json-report-file=../current-backend-results.json
BACKEND_EXIT_CODE=$?
cd ..
```

#### Frontend Tests (vitest)
```bash
cd frontend
npx vitest run --reporter=json --outputFile=../current-frontend-results.json
FRONTEND_EXIT_CODE=$?
cd ..
```

#### E2E Tests (si existen)
```bash
npx playwright test --reporter=json --output=current-e2e-results.json
E2E_EXIT_CODE=$?
```

### 4. Analizar Resultados

Parsear los archivos JSON:
- `current-backend-results.json`
- `current-frontend-results.json`

Extraer:
- Tests totales actuales
- Tests passed actuales
- Tests failed actuales
- **Lista de tests que fallaron**

### 5. Comparar con Baseline

```javascript
// Lógica de comparación

const baseline = JSON.parse(fs.readFileSync('.baselines/latest.json'));
const current = {
  total: currentBackend.total + currentFrontend.total,
  passed: currentBackend.passed + currentFrontend.passed,
  failed: currentBackend.failed + currentFrontend.failed
};

// Tests nuevos agregados
const newTests = current.total - baseline.tests.total;

// Tests que pasaban antes y ahora fallan (REGRESSION)
const regressionFailures = [];

// Si hay fallos en tests que existían antes
if (current.failed > 0) {
  // Identificar cuáles tests fallaron
  // Verificar si esos tests existían en el baseline
  // Si existían y pasaban → REGRESSION DETECTED
}
```

### 6. Detectar Regression

**Regression detectada si:**
- Hay tests que **existían antes** y **pasaban**
- Pero ahora **fallan**

**NO es regression si:**
- Tests nuevos fallan (esos aún están en desarrollo)
- Tests que ya fallaban en baseline siguen fallando

### 7. Generar Reporte

#### Si TODO pasa (✅ Ideal)
```markdown
# 🔄 Regression Testing Results

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Baseline (Antes del cambio)
- Tests: 156/156 passed
- Backend: 98/98
- Frontend: 58/58
- Timestamp: 2026-03-08 10:30:00

## Current (Después del cambio)
- Tests: 179/179 passed (+23 nuevos)
- Backend: 113/113 (+15)
- Frontend: 66/66 (+8)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ REGRESSION TESTING PASSED

✅ Ningún test viejo se rompió
✅ 23 tests nuevos agregados (todos pasan)
✅ Safe to merge

## Tests Nuevos Agregados:
- test_notification_service.py (8 tests)
- test_notification_router.py (5 tests)
- NotificationBell.test.tsx (6 tests)
- useNotifications.test.tsx (4 tests)
```

#### Si HAY REGRESSION (❌ Crítico)
```markdown
# ❌ REGRESSION DETECTED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⛔ WORKFLOW BLOQUEADO

## Baseline
- Tests: 156/156 passed

## Current
- Tests: 175/179 passed
- **4 tests FALLARON** ❌

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Tests que SE ROMPIERON (Regression):

### 1. backend/tests/auth/test_login.py
**Test:** "test_login_with_valid_credentials"
**Status antes:** PASSED
**Status ahora:** FAILED

**Error:**
```
AssertionError: 500 != 200
  response = client.post("/api/v1/auth/login", json=payload)
  assert response.status_code == 200
```

**Root Cause Analysis:**
El nuevo `notification_service.py` importa `auth_service` causando
inicializacion circular. auth_service se inicializa antes de que la
sesion de SQLAlchemy este disponible.

**Solucion sugerida:**
1. Mover import de auth_service a nivel de funcion, no top-level
2. O usar Depends() con lazy injection

**Checkpoint:** .checkpoints/02-backend.md (linea 125)

---

### 2. backend/tests/courses/test_enrollment.py
**Test:** "test_enroll_user_in_course"
**Status antes:** PASSED
**Status ahora:** ❌ FAILED

**Error:**
```
Expected: enrollment created
Received: Foreign key constraint failed

FOREIGN KEY constraint failed on table `enrollments`
```

**Root Cause Analysis:**
Nueva migración `add_notifications_table` modificó foreign keys.
El campo `userId` ahora referencia tabla incorrecta.

**Solución sugerida:**
1. Revisar migración: prisma/migrations/20260308_add_notifications/
2. Corregir foreign key constraint
3. Re-ejecutar migration

**Checkpoint:** .checkpoints/01-docker.md (migración de BD)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Acciones Requeridas:

1. ⛔ NO CONTINUAR con el workflow
2. 🔍 Revisar checkpoints mencionados arriba
3. 🛠️  Corregir los issues identificados
4. 🔄 Re-ejecutar regression testing
5. ✅ Solo avanzar cuando regression pase

## Comandos útiles:

```bash
# Ver logs completos
cat .checkpoints/04-regression-full.log

# Ver tests fallidos
cat current-backend-results.json | jq '.testResults[] | select(.status == "failed")'

# Revertir último checkpoint
git diff .checkpoints/02-backend.md

# Re-ejecutar solo tests rotos
cd backend && python -m pytest tests/auth/test_login.py -v
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📊 Output Files Generados

1. **current-backend-results.json** - Resultados completos backend
2. **current-frontend-results.json** - Resultados completos frontend
3. **.checkpoints/04-regression-report.md** - Reporte markdown
4. **.checkpoints/04-regression-full.log** - Log completo de ejecución
5. **.checkpoints/04-regression-comparison.json** - Comparación numérica

---

## 🔄 Integration con Workflow

Este skill se ejecuta en **FASE 4** después de que los agentes implementan:

```
FASE 2: backend-implementor
  ↓ (genera código + tests nuevos)
FASE 3: frontend-builder
  ↓ (genera código + tests nuevos)
FASE 4: 04-run-regression  ← Ejecuta AQUÍ
  ↓
  ├─ ✅ Pasa → Continuar a FASE 5
  └─ ❌ Falla → BLOQUEAR workflow
```

---

## 🛠️ Herramientas a Usar

- **Bash**: Ejecutar npm test, npx playwright
- **Read**: Leer baseline.json y resultados actuales
- **Write**: Generar reportes en .checkpoints/
- **Grep**: Buscar en logs de tests
- **AskUserQuestion**: Si hay regression, preguntar qué hacer

---

## 🚨 Decision Tree

```
¿Baseline existe?
├─ NO → ERROR: Ejecuta skill 01 primero
└─ SÍ → Continuar

Ejecutar todos los tests
  ↓
¿Todos los tests pasan?
├─ SÍ → ✅ REGRESSION PASSED
│        Mostrar tabla comparativa
│        Continuar workflow
│
└─ NO → ¿Tests que fallan existían antes?
         ├─ NO (tests nuevos) → ⚠️  WARNING
         │                       Tests nuevos fallan
         │                       Reportar pero continuar
         │
         └─ SÍ (tests viejos) → ❌ REGRESSION DETECTED
                                 Generar reporte detallado
                                 BLOQUEAR workflow
                                 Pedir corrección
```

---

## 📝 Smoke Tests Priority

Si el proyecto tiene `__tests__/regression/smoke-tests.test.ts`, ejecutar PRIMERO estos tests:
- Son tests críticos que NUNCA deben fallar
- Si smoke tests fallan → ALERTA MÁXIMA
- Ej: login, registro, enrollment básico

---

## 💡 Tips de Implementación

1. **Timeout largo**: Tests completos pueden tardar 5-10 min
2. **Paralelización**: Ejecutar backend y frontend en paralelo si es posible
3. **Logs detallados**: Guardar TODO el output para debugging
4. **Root cause analysis**: Intentar identificar por qué falló
5. **Actionable feedback**: Sugerir cómo arreglar el problema

---

**Duración estimada:** 5-10 minutos (depende del tamaño de la suite)
**Exit code:** 0 si pasa, 1 si falla regression
