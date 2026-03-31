# Skill: Orchestrate Feature Workflow

**Purpose:** Coordinar workflow completo para implementar una feature nueva
**Duration:** 20-60 minutos (depende de complejidad)
**Mode:** Semi-automático (con checkpoints de aprobación)
**Critical:** ⚠️ SÍ - Workflow principal del sistema

---

## 🎯 Objetivo

Implementar una feature completa de principio a fin, coordinando múltiples agentes especializados, con regression testing automático que garantiza que NADA se rompe.

---

## 📋 Fases del Workflow

```
┌────────────────────────────────────────────────────┐
│  FASE 0: Baseline Capture                          │
│  Captura estado inicial                            │
└────────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────┐
│  FASE 1: Docker/Infra (Opcional)                   │
│  Si la feature necesita cambios de infraestructura │
└────────────────────────────────────────────────────┘
                    ↓
           [Checkpoint: Aprobar?]
                    ↓
┌────────────────────────────────────────────────────┐
│  FASE 2: Backend Implementation                    │
│  backend-implementor agent                         │
└────────────────────────────────────────────────────┘
                    ↓
           [Checkpoint: Aprobar?]
                    ↓
┌────────────────────────────────────────────────────┐
│  FASE 3: Frontend Implementation                   │
│  frontend-builder agent                            │
└────────────────────────────────────────────────────┘
                    ↓
           [Checkpoint: Aprobar?]
                    ↓
┌────────────────────────────────────────────────────┐
│  FASE 4: QA + Regression Testing ⚠️ CRÍTICO        │
│  - Tests nuevos                                    │
│  - Regression completo                             │
│  - Architecture validation                         │
└────────────────────────────────────────────────────┘
                    ↓
      ¿Regression passed?
      ├─ NO → BLOQUEAR
      └─ SÍ → Continuar
                    ↓
┌────────────────────────────────────────────────────┐
│  FASE 5: Comparación Before/After                  │
│  Tabla comparativa de métricas                     │
└────────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────┐
│  FASE 6: Visual Validation                         │
│  Playwright MCP - Validación en navegador          │
└────────────────────────────────────────────────────┘
                    ↓
           [Checkpoint Final]
                    ↓
                ✅ DONE
```

---

## 🚀 Implementación Paso a Paso

### FASE 0: Baseline Capture

```markdown
Ejecutar skill: 01-capture-baseline

Output esperado:
- .baselines/latest.json creado
- Snapshot de estado actual guardado
```

**Checkpoint:**
```
📸 Baseline capturado exitosamente

Snapshot:
- Tests: 156/156 passed
- Coverage: Backend 82%, Frontend 76%

¿Continuar con la implementación? (y/n)
```

---

### FASE 1: Docker/Infra (Condicional)

**Condición:** Solo ejecutar si la descripción de la feature menciona:
- "docker"
- "base de datos"
- "infraestructura"
- "migración"
- "servicio nuevo"

**Invocación:**
```markdown
Invocar agente: docker-wsl2-devops

Prompt:
"Proyecto: {PROJECT_PATH}
Tarea: {FEATURE_DESCRIPTION}
Contexto: Estamos en la FASE 1 de un workflow completo.

Por favor implementa los cambios de infraestructura necesarios:
- Docker Compose si se necesita servicio nuevo
- Migraciones de base de datos
- Variables de entorno
- Volúmenes y networking

Genera:
1. Archivos de configuración
2. Scripts de setup
3. Documentación de cambios

Guarda resumen en: .checkpoints/01-docker.md"
```

**Herramienta:** `Task tool` con `subagent_type: docker-wsl2-devops`

**Output esperado:**
- `.checkpoints/01-docker.md` con cambios realizados
- Archivos de infraestructura creados/modificados

**Checkpoint:**
```
🐳 Fase Docker completada

Cambios:
- docker-compose.yml: Agregado servicio notification-worker
- Migración: 20260308_add_notifications_table.sql
- .env: Agregadas 3 variables nuevas

📋 Revisar: .checkpoints/01-docker.md

¿Continuar con Backend? (y/n)
```

---

### FASE 2: Backend Implementation

**Invocación:**
```markdown
Invocar agente: backend-implementor

Prompt:
"Proyecto: {PROJECT_PATH}/backend
Framework: {BACKEND_FRAMEWORK} (ej: Express, FastAPI)
Tarea: {FEATURE_DESCRIPTION}

Contexto previo:
{Contenido de .checkpoints/01-docker.md si existe}

Por favor implementa la feature completa en el backend:
1. Services (lógica de negocio)
2. Controllers (manejo de requests)
3. Routes (endpoints API)
4. Types/Interfaces
5. Tests unitarios (>=80% coverage)
6. Tests de integración

Organiza los tests en:
backend/src/__tests__/features/{feature-name}/

Genera también:
- README para la feature
- Documentación OpenAPI
- Story Coverage Matrix

Guarda resumen en: .checkpoints/02-backend.md"
```

**Herramienta:** `Task tool` con `subagent_type: backend-implementor`

**Output esperado:**
- Código backend implementado
- Tests creados
- `.checkpoints/02-backend.md` con resumen

**Checkpoint:**
```
📦 Fase Backend completada

Implementado:
- notification.service.ts (250 líneas)
- notification.controller.ts (120 líneas)
- notification.routes.ts (45 líneas)

Tests creados:
- notification.service.test.ts (8 tests)
- notification.controller.test.ts (5 tests)
- Coverage: 85%

📋 Revisar: .checkpoints/02-backend.md

¿Continuar con Frontend? (y/n)
```

---

### FASE 3: Frontend Implementation

**Invocación:**
```markdown
Invocar agente: frontend-builder

Prompt:
"Proyecto: {PROJECT_PATH}/frontend
Framework: {FRONTEND_FRAMEWORK} (ej: React, Vue)
Tarea: {FEATURE_DESCRIPTION}

Contexto previo:
{Contenido de .checkpoints/02-backend.md}

API Endpoints disponibles:
{Extraer endpoints del checkpoint backend}

Por favor implementa la feature completa en el frontend:
1. Components (UI components)
2. Pages (si necesita página nueva)
3. Hooks (custom hooks)
4. Services (API clients)
5. State management (Zustand/Redux)
6. Tests (React Testing Library)
7. Storybook stories (opcional)

Organiza los tests en:
frontend/src/components/{feature-name}/

Genera también:
- UX Design decisions doc
- Component hierarchy diagram

Guarda resumen en: .checkpoints/03-frontend.md"
```

**Herramienta:** `Task tool` con `subagent_type: frontend-builder`

**Output esperado:**
- Código frontend implementado
- Tests creados
- `.checkpoints/03-frontend.md` con resumen

**Checkpoint:**
```
🎨 Fase Frontend completada

Implementado:
- NotificationBell.tsx (180 líneas)
- NotificationDropdown.tsx (95 líneas)
- useNotifications.ts hook (60 líneas)
- notificationService.ts (45 líneas)

Tests creados:
- NotificationBell.test.tsx (6 tests)
- useNotifications.test.ts (4 tests)
- Coverage: 78%

📋 Revisar: .checkpoints/03-frontend.md

¿Continuar con QA? (y/n)
```

---

### FASE 4: QA + Regression Testing ⚠️ CRÍTICO

**Esta es la fase MÁS IMPORTANTE - aquí se detecta si algo se rompió**

#### 4.1: Tests Nuevos
```markdown
Ejecutar tests de la feature nueva:

Backend:
cd backend && npm test -- features/notifications/

Frontend:
cd frontend && npm test -- notifications
```

#### 4.2: Regression Completo
```markdown
Ejecutar skill: 04-run-regression

Este skill:
1. Ejecuta TODOS los tests (viejos + nuevos)
2. Compara con baseline
3. Detecta si algún test viejo se rompió
4. Genera reporte detallado
```

**Output esperado:**

**Si TODO pasa (✅):**
```
🧪 FASE 4: QA + Regression

4.1: Tests Nuevos
  ✅ Backend: 13/13 passed
  ✅ Frontend: 10/10 passed

4.2: Regression Testing
  ✅ 156/156 tests viejos passed
  ✅ 23/23 tests nuevos passed
  ✅ Total: 179/179 passed

✅ REGRESSION PASSED - Safe to continue
```

**Si HAY REGRESSION (❌):**
```
🧪 FASE 4: QA + Regression

4.1: Tests Nuevos
  ✅ Backend: 13/13 passed
  ✅ Frontend: 10/10 passed

4.2: Regression Testing
  ❌ 152/156 tests viejos passed (4 ROTOS)
  ✅ 23/23 tests nuevos passed

❌ REGRESSION DETECTED

Tests rotos:
1. auth.test.ts: login flow
2. course.test.ts: enrollment

⛔ WORKFLOW BLOQUEADO

Ver detalles: .checkpoints/04-regression-report.md

¿Qué deseas hacer?
1. Ver detalles de tests rotos
2. Revertir fase backend
3. Revertir fase frontend
4. Cancelar workflow
```

**Si hay regression → DETENER workflow aquí. NO continuar.**

---

### FASE 5: Comparación Before/After

```markdown
Ejecutar skill: 05-compare-baseline

Genera tabla comparativa:
- Tests antes vs después
- Coverage antes vs después
- Archivos modificados
- Líneas de código agregadas
```

**Output esperado:**
```
📊 FASE 5: Comparación Before/After

┌─────────────────┬─────────┬─────────┬──────────┐
│ Métrica         │ Antes   │ Después │ Cambio   │
├─────────────────┼─────────┼─────────┼──────────┤
│ Tests totales   │ 156     │ 179     │ +23 ✅   │
│ Tests passed    │ 156     │ 179     │ +23 ✅   │
│ Tests failed    │ 0       │ 0       │ 0 ✅     │
│ Backend cov.    │ 82%     │ 83%     │ +1% ✅   │
│ Frontend cov.   │ 76%     │ 78%     │ +2% ✅   │
│ LOC backend     │ 12,450  │ 12,865  │ +415     │
│ LOC frontend    │ 8,230   │ 8,565   │ +335     │
└─────────────────┴─────────┴─────────┴──────────┘

✅ Todos los indicadores mejoraron o se mantuvieron
```

---

### FASE 6: Visual Validation

```markdown
Usar Playwright MCP para validar visualmente:

1. Navegar a la página principal
2. Verificar que el NotificationBell aparece
3. Click en bell
4. Verificar dropdown se abre
5. Verificar contador funciona
6. Capturar screenshots

Comparar con baselines visuales si existen
```

**Herramienta:** Playwright MCP tools

**Output esperado:**
```
📸 FASE 6: Validación Visual

✅ Navegación a dashboard: OK
✅ NotificationBell visible: OK
✅ Click en bell: Dropdown abre correctamente
✅ Badge muestra "3 notificaciones": OK
✅ Scroll en dropdown: OK
✅ No errors en consola: OK

Screenshots guardados en: reports/visual/
```

---

## 📊 Resumen Final

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 WORKFLOW COMPLETADO EXITOSAMENTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: Sistema de Notificaciones Push
Duración: 45 minutos

✅ FASE 0: Baseline capturado
✅ FASE 1: Infraestructura (Docker + BD migration)
✅ FASE 2: Backend (415 LOC, 13 tests)
✅ FASE 3: Frontend (335 LOC, 10 tests)
✅ FASE 4: Regression PASSED (179/179 tests)
✅ FASE 5: Métricas mejoraron
✅ FASE 6: Validación visual OK

📁 Checkpoints:
   - .checkpoints/00-baseline.json
   - .checkpoints/01-docker.md
   - .checkpoints/02-backend.md
   - .checkpoints/03-frontend.md
   - .checkpoints/04-regression-report.md
   - .checkpoints/05-comparison.md
   - .checkpoints/06-visual.md

📊 Reportes:
   - reports/consolidated/dashboard.html
   - reports/visual/

🔄 Comparación:
   - Tests: 156 → 179 (+23)
   - Coverage: 79% → 80.5% (+1.5%)
   - NINGÚN TEST ROTO ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

¿Aprobar feature para merge? (y/n)
```

---

## 🚨 Manejo de Errores

### Si un agente falla
```
❌ Error en FASE 2 (Backend)

El agente backend-implementor reportó error:
- No se pudo generar controllers
- Problema con tipos de TypeScript

Opciones:
1. Revisar checkpoint: .checkpoints/02-backend.md
2. Reintentar fase backend
3. Cancelar workflow
4. Continuar de todas formas (no recomendado)

¿Qué deseas hacer? (1/2/3/4)
```

### Si regression falla
```
❌ REGRESSION FAILED en FASE 4

⛔ WORKFLOW BLOQUEADO - NO CONTINUAR

4 tests se rompieron con los cambios.
Ver detalles en: .checkpoints/04-regression-report.md

Acciones requeridas:
1. Arreglar los tests rotos
2. Re-ejecutar workflow desde checkpoint

NO puedes avanzar hasta resolver regression.
```

---

## 💾 Checkpoint System

Cada fase guarda un checkpoint que permite:
- **Resume**: Continuar desde última fase exitosa
- **Rollback**: Revertir a fase anterior
- **Debug**: Ver qué hizo cada agente

Estructura de checkpoint:
```markdown
# Checkpoint: FASE 2 - Backend Implementation

**Timestamp:** 2026-03-08 10:45:00
**Agente:** backend-implementor
**Duración:** 12 minutos
**Status:** ✅ SUCCESS

## Archivos Modificados:
- backend/src/services/notification.service.ts (NEW)
- backend/src/controllers/notification.controller.ts (NEW)
[...]

## Tests Creados:
- 13 tests nuevos
- Coverage: 85%

## Output Completo:
[... log completo del agente ...]
```

---

**Duración estimada:** 20-60 minutos (varía según complejidad de la feature)
**Mode:** Semi-automático (requiere aprobación en cada checkpoint)
