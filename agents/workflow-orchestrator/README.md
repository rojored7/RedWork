# Workflow Orchestrator Agent

**Automated Development Workflows with Guaranteed Quality**

Un agente especializado para Claude Code que coordina el desarrollo de software con **regression testing automático**, garantizando que ningún cambio rompa funcionalidad existente.

---

## 🎯 ¿Qué es esto?

El **Workflow Orchestrator** es un agente que:

1. **Captura el estado actual** de tu proyecto (tests, coverage, visual) ANTES de hacer cambios
2. **Coordina otros agentes** especializados (backend, frontend, docker, qa) para implementar features/fixes
3. **Ejecuta TODOS los tests** (viejos + nuevos) después de cada cambio
4. **BLOQUEA el workflow** si algún test viejo se rompe (regression detectado)
5. **Genera reportes** detallados de qué cambió y qué se rompió

**Objetivo principal**: Prevenir que bugs lleguen a producción garantizando que NADA se rompa con tus cambios.

---

## 🚀 Inicio Rápido

### 1. Instalar el Sistema

En tu proyecto, invoca el agente:

```
En Claude Code:
"Inicializa el workflow system en este proyecto"
```

O manualmente:
```bash
# Copiar agent a tu .claude/agents
cp -r workflow-orchestrator ~/.claude/agents/

# En tu proyecto
cd tu-proyecto/
```

El agente detectará automáticamente:
- Tipo de proyecto (Node.js, Python, etc.)
- Frameworks (Express, React, etc.)
- Test runners (Jest, Vitest, etc.)

Y creará:
- `.baselines/` - Estados de referencia
- `.checkpoints/` - Puntos de guardado
- `reports/` - Reportes de tests/visual
- `.workflow-config.json` - Configuración

### 2. Usar el Workflow

**Para implementar una feature nueva:**
```
En Claude Code:
"Implementar sistema de notificaciones push"
```

El agente ejecutará automáticamente:
- ✅ Captura baseline
- ✅ Coordina agentes (docker → backend → frontend)
- ✅ Ejecuta regression testing
- ✅ Validación visual
- ⛔ BLOQUEA si algo se rompe

**Para fix rápido:**
```
En Claude Code:
"Corregir bug en cálculo de progreso"
```

Workflow automático (sin pausas):
- ✅ Captura baseline
- ✅ Backend + Frontend
- ✅ Regression testing
- ⛔ BLOQUEA si regression falla

---

## 📚 Skills Disponibles

El agente tiene 8 skills especializadas:

### Core Workflows

#### `02-orchestrate-feature` - Workflow Completo
**Uso:** Implementar features nuevas con control total

**Fases:**
```
FASE 0: Baseline Capture (automático)
   ↓
FASE 1: Docker/Infra (opcional, con aprobación)
   ↓ [Checkpoint: ¿Aprobar?]
FASE 2: Backend (con aprobación)
   ↓ [Checkpoint: ¿Aprobar?]
FASE 3: Frontend (con aprobación)
   ↓ [Checkpoint: ¿Aprobar?]
FASE 4: Regression Testing ⚠️ CRÍTICO
   ↓ Si falla → BLOQUEAR
FASE 5: Comparación Before/After
   ↓
FASE 6: Visual Validation
   ↓ [Aprobación Final]
```

**Cuándo usar:**
- Features nuevas complejas
- Cambios que afectan múltiples módulos
- Cuando necesitas control y visibilidad completa

**Ejemplo:**
```
Usuario: "Implementar sistema de notificaciones con WebSockets"

Agente:
📸 FASE 0: Capturando baseline...
   ✅ 156 tests passed
   ✅ Coverage: Backend 82%, Frontend 76%

🐳 FASE 1: Configurando Docker...
   ✅ Redis agregado para pub/sub
   [Checkpoint guardado: .checkpoints/01-docker.md]

   ¿Aprobar y continuar? (y/n)
```

---

#### `03-orchestrate-fix` - Workflow Rápido
**Uso:** Fixes y refactors automáticos

**Fases:**
```
FASE 0: Baseline (automático)
   ↓
FASE 1: Docker (solo si necesario, automático)
   ↓
FASE 2: Backend (automático)
   ↓
FASE 3: Frontend (automático)
   ↓
FASE 4: Regression ⚠️ (bloquea si falla)
```

**Diferencia con orchestrate-feature:**
- ❌ Sin pausas entre fases
- ❌ Sin preguntas de aprobación
- ✅ Todo automático
- ✅ Solo bloquea si regression falla

**Cuándo usar:**
- Bug fixes pequeños
- Refactors sin cambio funcional
- Hotfixes urgentes
- Mejoras de performance
- Code cleanup

**Ejemplo:**
```
Usuario: "Corregir bug en cálculo de progreso"

Agente:
🔧 Fix Workflow - Modo Automático

📸 FASE 0: Baseline
   ✅ Capturado

📦 FASE 2: Backend
   ✅ Modificado: progress.service.ts
   ✅ Test agregado

🎨 FASE 3: Frontend
   ✅ Modificado: ProgressBar.tsx

🔄 FASE 4: Regression
   ✅ 158/158 tests passed
   ✅ REGRESSION PASSED

✅ Fix completado en 8 minutos
```

---

### Skills Individuales

#### `01-capture-baseline` - Capturar Estado
**Propósito:** Guardar snapshot del proyecto antes de cambios

**Captura:**
- Tests: total, passed, failed
- Coverage: backend %, frontend %
- Código: archivos, LOC
- Timestamp

**Output:** `.baselines/latest.json`

**Cuándo ejecutar:**
- SIEMPRE antes de implementar algo
- Antes de merge a main
- Después de cada release

**Ejemplo:**
```bash
# Manual
"Captura baseline del proyecto"

# Automático (parte de workflows)
[Se ejecuta automáticamente en FASE 0]
```

---

#### `04-run-regression` - Testing Crítico ⚠️
**Propósito:** Ejecutar TODOS los tests y detectar regression

**Proceso:**
1. Carga baseline de `.baselines/latest.json`
2. Ejecuta backend tests (`npm test`)
3. Ejecuta frontend tests (`npm test`)
4. Compara resultados con baseline
5. Detecta tests que SE ROMPIERON
6. Genera reporte detallado

**Output (éxito):**
```
✅ REGRESSION PASSED

Tests antes: 156/156 passed
Tests ahora: 179/179 passed (+23 nuevos)

0 tests rotos
```

**Output (falla - CRÍTICO):**
```
❌ REGRESSION DETECTED

⛔ WORKFLOW BLOQUEADO

Tests que SE ROMPIERON:
1. auth.test.ts: login flow
   - Expected: 200 OK
   - Received: 500 Internal Server Error
   - Root Cause: Inicialización circular

Acciones Requeridas:
⛔ NO CONTINUAR
🔍 Revisar .checkpoints/02-backend.md
🛠️ Corregir el issue
🔄 Re-ejecutar workflow
```

**Por qué es CRÍTICO:**
- Detecta si tus cambios rompieron algo existente
- BLOQUEA el workflow si algo falla
- Previene bugs en producción
- NO se puede saltear

---

#### `05-compare-baseline` - Comparación Before/After
**Propósito:** Mostrar cómo cambió el proyecto

**Output:**
```
📊 Comparación Before/After

| Métrica | Antes | Después | Cambio |
|---------|-------|---------|--------|
| Tests totales | 156 | 179 | +23 ✅ |
| Tests passed | 156 | 179 | +23 ✅ |
| Tests failed | 0 | 0 | 0 ✅ |
| Backend cov. | 82% | 83% | +1% ✅ |
| Frontend cov. | 76% | 78% | +2% ✅ |
| LOC backend | 12,450 | 12,865 | +415 |
| LOC frontend | 8,230 | 8,565 | +335 |

✅ Veredicto: Safe to merge
```

---

#### `06-validate-architecture` - Reglas CAS
**Propósito:** Validar arquitectura y convenciones

**Valida:**
- Layering: Controllers → Services → Repositories
- Naming: kebab-case, PascalCase, camelCase
- Circular dependencies
- Import order
- File organization

**Modo:** Advisory (solo advierte, NO bloquea)

**Output:**
```
🏛️  Validación de Arquitectura

✅ Layering: Cumple
⚠️  Naming: 2 violations
   - notification_Service.py (debe ser notification_service.py)
✅ Circular dependencies: Ninguna
⚠️  Import order: 3 violations

📊 CAS Validation: PASSED with warnings
6 violations (modo advisory - no bloquea)

💡 Recomendaciones:
1. Renombrar archivos a kebab-case
2. Reordenar imports (npm run lint:fix)
```

---

#### `07-visual-validation` - Validación Visual
**Propósito:** Verificar UI con Playwright MCP

**Proceso:**
1. Navega a páginas afectadas
2. Verifica componentes visibles
3. Interactúa (clicks, forms)
4. Captura screenshots
5. Detecta errores de consola
6. Verifica network requests

**Output:**
```
📸 FASE 6: Validación Visual

🌐 Navegación: Dashboard
   ✅ Página carga (1.2s)
   ✅ No errors en consola

🔍 Componente: NotificationBell
   ✅ Visible en header
   ✅ Badge muestra "3"

👆 Interacción: Click en bell
   ✅ Dropdown abre
   ✅ 3 notificaciones visibles

📡 Network Requests
   ✅ GET /api/notifications → 200 OK

✅ Validación Visual PASSED
```

---

#### `08-init-project` - Setup Inicial
**Propósito:** Inicializar proyecto con workflow system

**Proceso:**
1. Detecta tipo de proyecto (Node.js, frameworks)
2. Crea directorios (`.baselines/`, `.checkpoints/`, `reports/`)
3. Copia templates (smoke-tests, arch-rules, config)
4. Crea `.workflow-config.json`
5. Actualiza `.gitignore`
6. Captura baseline inicial
7. Genera guía de uso

**Output:**
```
🎬 Inicializando proyecto con Workflow System...

📍 Proyecto detectado:
   Tipo: Python + React
   Backend: FastAPI (pytest)
   Frontend: React (Vitest)

Creando estructura...
   .baselines/
   .checkpoints/
   reports/

Copiando templates...
   smoke_tests.py
   .arch-rules.py
   .workflow-config.json

📸 Capturando baseline inicial...
   ✅ 156/156 tests passed
   ✅ Baseline guardado

✅ Proyecto inicializado exitosamente!
```

---

## 🔧 Configuración

### `.workflow-config.json`

```json
{
  "version": "1.0.0",
  "project": {
    "backend": {
      "framework": "express",
      "testRunner": "jest",
      "path": "backend/"
    },
    "frontend": {
      "framework": "react",
      "testRunner": "vitest",
      "path": "frontend/"
    }
  },
  "workflows": {
    "regression": {
      "enabled": true,
      "blockOnFailure": true  // ⚠️ CRÍTICO
    },
    "architecture": {
      "enabled": true,
      "mode": "advisory"  // Solo advierte
    }
  },
  "thresholds": {
    "minCoverage": 70,
    "maxRegressionFailures": 0  // ⚠️ Cero tolerancia
  }
}
```

### `.arch-rules.ts`

Define reglas de arquitectura personalizadas:

```typescript
export const architectureRules = {
  layering: {
    controllers: {
      canImport: ['services', 'types'],
      cannotImport: ['repositories', 'utils/prisma']
    }
  },
  naming: {
    files: 'kebab-case',
    classes: 'PascalCase'
  }
};
```

---

## 📊 Estructura de Archivos

```
tu-proyecto/
├── .baselines/
│   ├── latest.json              # Baseline más reciente
│   ├── 2026-03-08-10-30.json   # Baselines históricos
│   └── ...
├── .checkpoints/
│   ├── 01-docker.md            # Estado después de docker
│   ├── 02-backend.md           # Estado después de backend
│   ├── 03-frontend.md          # Estado después de frontend
│   ├── 04-regression-report.md # Reporte de regression
│   ├── 05-comparison.md        # Comparación before/after
│   ├── 06-architecture.md      # Validación CAS
│   └── 07-visual-validation.md # Validación visual
├── reports/
│   ├── coverage/               # Reportes de coverage
│   ├── visual/                 # Screenshots
│   └── consolidated/           # Reportes consolidados
├── .workflow-config.json       # Configuración
├── .arch-rules.ts              # Reglas de arquitectura
└── backend/src/__tests__/
    └── regression/
        └── smoke-tests.test.ts # Tests críticos
```

---

## 🎓 Guía de Uso

### Flujo Típico de Desarrollo

1. **Antes de empezar:**
   ```
   "Captura baseline del proyecto"
   ```

2. **Implementar feature:**
   ```
   "Implementar sistema de badges gamificados"
   ```

   El agente:
   - Captura baseline automáticamente
   - Coordina docker-wsl2-devops (si necesario)
   - Invoca backend-implementor
   - Pausa para aprobación ← Revisas checkpoint
   - Invoca frontend-builder
   - Pausa para aprobación ← Revisas checkpoint
   - Ejecuta regression testing ← CRÍTICO
   - Si pasa → Continúa
   - Si falla → BLOQUEA y reporta

3. **Si regression falla:**
   ```
   Agente te muestra:
   ❌ Test roto: badge.service.test.ts
   Causa: Variable no inicializada

   Acciones:
   1. Revisar .checkpoints/02-backend.md
   2. Corregir el issue
   3. Re-ejecutar "Continuar workflow"
   ```

4. **Aprobación final:**
   ```
   ✅ Todos los tests pasan
   ✅ Coverage incrementó +2%
   ✅ Validación visual passed

   ¿Aprobar feature? (y/n)
   ```

### Comandos Útiles

**Desde Makefile:**
```bash
make -f Makefile.workflow help
make -f Makefile.workflow workflow-baseline
make -f Makefile.workflow workflow-regression
make -f Makefile.workflow workflow-status
```

**Desde Claude Code:**
```
"Captura baseline"
"Ejecuta regression"
"Compara con baseline"
"Valida arquitectura"
"Validación visual de dashboard"
```

---

## 🚨 Regression Testing - Detalles

### ¿Por qué es CRÍTICO?

Imagina este escenario:

```
Estado inicial:
- 156 tests, todos pasan ✅

Implementas: Sistema de notificaciones
- Agregas 23 tests nuevos
- TOTAL: 179 tests

Regression ejecuta:
- 156 tests viejos → 154 pasan, 2 fallan ❌
- 23 tests nuevos → 23 pasan ✅

⛔ WORKFLOW BLOQUEADO
Motivo: 2 tests viejos se rompieron (auth.test.ts, enrollment.test.ts)
```

**Sin regression testing:**
- Esos 2 bugs pasarían desapercibidos
- Llegarían a producción
- Romperían funcionalidad existente

**Con regression testing:**
- Workflow se BLOQUEA inmediatamente
- Te muestra exactamente qué se rompió
- No puedes continuar hasta corregirlo

### ¿Qué detecta?

1. **Tests que fallaban y ahora pasan** → OK (fix exitoso)
2. **Tests que pasaban y ahora fallan** → ⛔ REGRESSION
3. **Tests nuevos que fallan** → ⚠️ Issues en código nuevo
4. **Coverage que baja** → ⚠️ Advertencia

### Configuración de Tolerancia

```json
{
  "thresholds": {
    "maxRegressionFailures": 0  // Cero tolerancia (recomendado)
  }
}
```

Si pones `maxRegressionFailures: 2`, permitiría hasta 2 tests rotos.
**NO RECOMENDADO** - Siempre usar 0.

---

## 🔄 Checkpoints y Resume

### ¿Qué son los Checkpoints?

Cada fase guarda su estado en `.checkpoints/XX-nombre.md`:

```markdown
# Backend Implementation - Checkpoint

**Feature:** Sistema de notificaciones
**Timestamp:** 2026-03-08 11:00:00
**Status:** ✅ Completed

## Cambios Realizados
- Controllers: notification.controller.ts
- Services: notification.service.ts
- Routes: notification.routes.ts
- Tests: 8 nuevos tests agregados

## Resumen
Implementado endpoint GET /api/notifications
con filtros por read/unread y paginación.

## Tests
✅ 8/8 tests nuevos passed
✅ No tests viejos rotos

## Next Steps
Continuar con frontend (skill 03-frontend)
```

### ¿Para qué sirven?

1. **Visibilidad:** Ver exactamente qué hizo cada agente
2. **Rollback:** Volver a fase anterior si algo sale mal
3. **Resume:** Continuar workflow después de pausa
4. **Debugging:** Entender qué se rompió y dónde

### Ejemplo de Resume

```
Usuario: "Continuar workflow desde checkpoint 3"

Agente:
📂 Cargando checkpoint: .checkpoints/03-frontend.md

Estado detectado:
✅ FASE 0: Baseline capturado
✅ FASE 1: Docker configurado
✅ FASE 2: Backend implementado
✅ FASE 3: Frontend implementado
⏸️  FASE 4: Regression - PENDIENTE

Continuando desde FASE 4...
```

---

## 🎯 Casos de Uso Reales

### Caso 1: Feature Nueva con Migración DB

```
Usuario: "Implementar sistema de badges gamificados con nueva tabla en DB"

Agente:
📸 FASE 0: Baseline
   ✅ Capturado

🐳 FASE 1: Docker/Infra
   Detectado: "nueva tabla" → Invocando docker-wsl2-devops
   ✅ Migración Prisma creada
   ✅ Schema actualizado
   [Checkpoint: .checkpoints/01-docker.md]
   ¿Aprobar? (y/n)

Usuario: y

📦 FASE 2: Backend
   Invocando backend-implementor
   ✅ Badge.service.ts creado
   ✅ Badge.controller.ts creado
   ✅ 12 tests agregados
   [Checkpoint: .checkpoints/02-backend.md]
   ¿Aprobar? (y/n)

Usuario: y

🎨 FASE 3: Frontend
   Invocando frontend-builder
   ✅ BadgeList.tsx creado
   ✅ useBadges.ts hook creado
   ✅ 8 tests agregados
   [Checkpoint: .checkpoints/03-frontend.md]
   ¿Aprobar? (y/n)

Usuario: y

🔄 FASE 4: Regression
   Ejecutando TODOS los tests...
   ✅ 156 tests viejos → 156 passed
   ✅ 20 tests nuevos → 20 passed
   ✅ REGRESSION PASSED

📊 FASE 5: Comparación
   Tests: 156 → 176 (+20)
   Coverage: 82% → 84% (+2%)
   ✅ Safe to merge

📸 FASE 6: Visual
   Navegando a /dashboard...
   ✅ BadgeList visible
   ✅ No console errors
   ✅ Screenshots capturados

━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Feature completada exitosamente

Duración: 25 minutos
Checkpoints: 6 fases guardadas
Reporte: reports/consolidated/badges-feature-report.md

¿Aprobar para merge? (y/n)
```

---

### Caso 2: Fix Rápido con Regression Failure

```
Usuario: "Corregir bug en cálculo de progreso de curso"

Agente:
🔧 Fix Workflow - Modo Automático

📸 FASE 0: Baseline
   ✅ Capturado (156 tests)

📦 FASE 2: Backend
   ✅ progress.service.ts modificado
   ✅ Test agregado: progress-calculation.test.ts

🎨 FASE 3: Frontend
   ✅ ProgressBar.tsx actualizado

🔄 FASE 4: Regression
   Ejecutando tests...
   ✅ 157 tests nuevos passed
   ❌ 2 tests viejos FALLARON

   ⛔ REGRESSION DETECTED

   Tests rotos:
   1. enrollment.test.ts: Enrollment progress calculation
      - Expected: 75%
      - Received: 100%
      - Line: enrollment.service.test.ts:145

   2. certificate.test.ts: Certificate generation trigger
      - Expected: Certificate generated at 100%
      - Received: Certificate generated at 75%
      - Line: certificate.service.test.ts:89

   Root Cause Analysis:
   El fix cambió la lógica de cálculo de progreso de:
   - Antes: (completedLessons / totalLessons) * 100
   - Ahora: (completedModules / totalModules) * 100

   Esto causó que enrollment.service.ts y certificate.service.ts
   calculen progreso incorrectamente.

   ⛔ WORKFLOW BLOQUEADO

   Acciones Requeridas:
   1. Revisar .checkpoints/02-backend.md
   2. Actualizar enrollment.service.ts para usar nueva lógica
   3. Actualizar certificate.service.ts
   4. Re-ejecutar workflow

Usuario: "OK, voy a corregir"

[Usuario corrige los servicios]

Usuario: "Corregido, re-ejecuta workflow"

Agente:
🔧 Re-ejecutando Fix Workflow...

🔄 FASE 4: Regression
   ✅ 159/159 tests passed
   ✅ REGRESSION PASSED

✅ Fix completado exitosamente
   2 servicios adicionales actualizados
   Duración total: 12 minutos
```

---

### Caso 3: Validación de Arquitectura

```
Usuario: "Valida la arquitectura del proyecto"

Agente:
🏛️  Validación de Arquitectura (CAS)

Verificando reglas...

✅ Layering: Cumple
   Routers -> Services -> Repositories
   245 archivos verificados

Naming conventions: 3 violations
   1. backend/app/services/notification_Service.py
      Expected: notification_service.py (snake_case)

   2. backend/app/utils/NotificationHelper.py
      Expected: notification_helper.py (snake_case)

   3. frontend/src/components/BadgeList/BadgeListComponent.tsx
      Expected: BadgeList.tsx (sin "Component" suffix)

✅ Circular dependencies: Ninguna detectada

⚠️  Import order: 5 violations
   1. notification.controller.ts:5
      External imports must come before internal

   2. notification.service.ts:12
      Relative imports must come after internal

   [... 3 más ...]

⚠️  File organization: 1 violation
   - src/notificationUtils.ts
     Debe estar en utils/ directory

━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 CAS Validation: PASSED with warnings

⚠️  9 violations detectadas (modo advisory)
   - 3 naming
   - 5 import order
   - 1 file organization

💡 Recomendaciones:
1. Renombrar archivos a kebab-case
2. Reordenar imports (auto-fixable):
   npm run lint:fix
3. Mover notificationUtils.ts a utils/

ℹ️  Modo Advisory: No bloquea el workflow
   Puedes continuar, pero considera arreglar estos issues

Reporte: .checkpoints/06-architecture-validation.md
```

---

## 🛠️ Troubleshooting

### Problema: Baseline no se captura

**Síntoma:**
```
❌ Error: Cannot read .baselines/latest.json
```

**Solución:**
```
"Captura baseline del proyecto"
```

O manualmente:
```bash
mkdir -p .baselines
```

---

### Problema: Regression siempre falla

**Síntoma:**
```
❌ REGRESSION DETECTED
Tests rotos: 10+
```

**Causas comunes:**
1. Baseline desactualizado (capturado hace mucho)
2. Tests viejos ya estaban rotos
3. Cambio legítimo que requiere actualizar tests

**Solución:**
```
# Opción 1: Re-capturar baseline (si tests viejos ya estaban rotos)
"Captura nuevo baseline"

# Opción 2: Actualizar tests para reflejar nuevos cambios
"Actualiza tests de [módulo] para nueva lógica"

# Opción 3: Revisar checkpoints para encontrar qué se rompió
"Muéstrame .checkpoints/04-regression-report.md"
```

---

### Problema: Docker containers no están corriendo

**Síntoma:**
```
⚠️  Servicios no están corriendo
Cannot connect to http://localhost:3000
```

**Solución:**
```bash
docker-compose up -d
make -f Makefile.workflow workflow-test-docker
```

---

### Problema: Tests muy lentos

**Síntoma:**
Regression testing toma >10 minutos

**Solución:**
```json
// .workflow-config.json
{
  "advanced": {
    "parallelExecution": {
      "enabled": true,  // ← Habilitar
      "maxConcurrency": 4  // ← Ajustar según CPU
    }
  }
}
```

---

## 📖 Referencia Rápida

### Comandos de Agente

| Comando | Skill | Descripción |
|---------|-------|-------------|
| "Inicializa workflow system" | 08-init-project | Setup inicial |
| "Captura baseline" | 01-capture-baseline | Snapshot actual |
| "Implementar [feature]" | 02-orchestrate-feature | Workflow completo |
| "Corregir [bug]" | 03-orchestrate-fix | Workflow rápido |
| "Ejecuta regression" | 04-run-regression | Solo testing |
| "Compara con baseline" | 05-compare-baseline | Before/After |
| "Valida arquitectura" | 06-validate-architecture | CAS |
| "Validación visual de [página]" | 07-visual-validation | Playwright MCP |

### Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `.baselines/latest.json` | Estado de referencia |
| `.checkpoints/*.md` | Estados de cada fase |
| `.workflow-config.json` | Configuración |
| `.arch-rules.ts` | Reglas de arquitectura |
| `reports/consolidated/` | Reportes finales |

### Thresholds Recomendados

```json
{
  "thresholds": {
    "minCoverage": 70,           // Mínimo 70% coverage
    "maxRegressionFailures": 0,  // ⚠️ Cero tolerancia
    "maxArchViolations": 5,      // Máximo 5 violations CAS
    "maxVisualDiff": 1.0         // 1% diff en screenshots
  }
}
```

---

## 🤝 Integración con CI/CD

### GitHub Actions Example

```yaml
name: Workflow Regression

on: [push, pull_request]

jobs:
  regression:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm install

      - name: Load baseline
        run: |
          if [ ! -f .baselines/latest.json ]; then
            echo "⚠️  No baseline found, capturing..."
            # Invoke workflow-orchestrator skill 01
          fi

      - name: Run regression tests
        run: |
          # Invoke workflow-orchestrator skill 04
          # This will run ALL tests and compare with baseline

      - name: Block if regression detected
        if: failure()
        run: |
          echo "❌ REGRESSION DETECTED - Blocking merge"
          exit 1
```

---

## 📝 Notas Finales

### Filosofía del Sistema

1. **Zero Regression Tolerance:** Ningún test viejo puede romperse
2. **Visibility First:** Todo cambio debe ser auditable
3. **Fail Fast:** Detectar problemas temprano
4. **Automation with Control:** Automatizar pero con checkpoints

### Mejores Prácticas

✅ **DO:**
- Capturar baseline antes de CADA feature
- Revisar checkpoints cuando workflow pausa
- Corregir violations de arquitectura (aunque no bloqueen)
- Mantener `.baselines/` en .gitignore

❌ **DON'T:**
- Saltear regression testing ("está bien, confío")
- Ignorar warnings de CAS repetidamente
- Modificar `.baselines/*.json` manualmente
- Subir `reports/` a git

---

## 🔗 Links Útiles

- **Agent Definition:** `agent.md`
- **Skills:** `skills/*.md`
- **Templates:** `templates/`
- **Makefile Helper:** `templates/Makefile.workflow`

---

## 📄 Licencia

Este agente es parte del sistema de desarrollo de `Curso_ciber` y puede ser reutilizado en cualquier proyecto que use Claude Code.

---

**Creado por:** workflow-orchestrator system
**Versión:** 1.0.0
**Última actualización:** 2026-03-08
