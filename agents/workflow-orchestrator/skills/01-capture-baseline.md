# Skill: Capture Baseline

**Purpose:** Capturar el estado completo del proyecto ANTES de hacer cualquier cambio
**Duration:** 3-5 minutos
**Critical:** ⚠️ SÍ - Necesario para regression testing

---

## 🎯 Objetivo

Capturar una fotografía completa del estado actual del proyecto:
- Todos los tests y sus resultados
- Coverage de código
- Screenshots visuales (baselines)
- Estado de la arquitectura

Este baseline se usará después para comparar y detectar si algo se rompió.

---

## 📋 Proceso

### 1. Detectar Tipo de Proyecto

```bash
# Leer package.json para detectar frameworks
```

Determinar:
- ¿Tiene backend? (backend/package.json)
- ¿Tiene frontend? (frontend/package.json)
- ¿Qué test runner? (Jest, Vitest, Pytest, etc.)
- ¿Tiene E2E? (Playwright, Cypress)

### 2. Crear Estructura de Directorios

```bash
mkdir -p .baselines
mkdir -p .checkpoints
mkdir -p reports
```

Agregar a .gitignore si no existe:
```
.baselines/
.checkpoints/
reports/
```

### 3. Ejecutar Tests Backend (si existe)

```bash
cd backend
npm test -- --json --outputFile=../temp-backend-results.json --passWithNoTests
cd ..
```

**Importante:** Usar `--passWithNoTests` para no fallar si no hay tests aún.

### 4. Ejecutar Tests Frontend (si existe)

```bash
cd frontend
npm test -- --reporter=json --outputFile=../temp-frontend-results.json --run
cd ..
```

### 5. Ejecutar Tests E2E (si existe)

```bash
# Solo si existe playwright.config.ts o cypress.json
npx playwright test --reporter=json --output=temp-e2e-results.json
```

### 6. Capturar Coverage (opcional)

```bash
# Backend coverage
cd backend && npm run test:coverage 2>/dev/null || true
# Frontend coverage
cd frontend && npm run test:coverage 2>/dev/null || true
```

### 7. Consolidar Resultados en JSON

Crear archivo `.baselines/baseline-TIMESTAMP.json` con estructura:

```json
{
  "timestamp": "2026-03-08T10:30:00Z",
  "project": {
    "path": "/full/path/to/project",
    "type": "nodejs",
    "backend": "express",
    "frontend": "react"
  },
  "tests": {
    "total": 156,
    "passed": 156,
    "failed": 0,
    "skipped": 0,
    "details": {
      "backend": {
        "total": 98,
        "passed": 98,
        "failed": 0
      },
      "frontend": {
        "total": 58,
        "passed": 58,
        "failed": 0
      }
    }
  },
  "coverage": {
    "backend": {
      "lines": 82.5,
      "branches": 78.3,
      "functions": 85.1,
      "statements": 82.5
    },
    "frontend": {
      "lines": 76.2,
      "branches": 71.8,
      "functions": 79.5,
      "statements": 76.2
    }
  },
  "visual": {
    "screenshots": 12,
    "baselines": [
      "e2e/visual-regression/baselines/dashboard-student.png",
      "e2e/visual-regression/baselines/course-detail.png"
    ]
  },
  "architecture": {
    "violations": 0,
    "warnings": 1,
    "details": []
  }
}
```

### 8. Crear Symlink "latest"

```bash
cd .baselines
ln -sf baseline-TIMESTAMP.json latest.json
cd ..
```

### 9. Limpiar Archivos Temporales

```bash
rm -f temp-backend-results.json
rm -f temp-frontend-results.json
rm -f temp-e2e-results.json
```

---

## 📊 Output Esperado

```
📸 Capturando baseline del proyecto...
   Proyecto: /Users/Itac/Proyectos/Curso_ciber/plataforma
   Timestamp: 2026-03-08-10-30-00

  📦 Ejecutando tests backend...
     ✅ 98/98 tests passed

  🎨 Ejecutando tests frontend...
     ✅ 58/58 tests passed

  🌐 Ejecutando tests E2E...
     ⏭️  Skipped (no E2E tests configured)

  📊 Capturando coverage...
     Backend: 82% lines, 78% branches
     Frontend: 76% lines, 72% branches

✅ Baseline guardado: .baselines/baseline-20260308-103000.json

📊 Snapshot Capturado:
┌─────────────────┬──────────┐
│ Tests totales   │ 156      │
│ Tests passed    │ 156      │
│ Tests failed    │ 0        │
│ Backend cov.    │ 82%      │
│ Frontend cov.   │ 76%      │
│ Visual screens  │ 0        │
└─────────────────┴──────────┘

💾 Baseline disponible en: .baselines/latest.json
```

---

## 🚨 Manejo de Errores

### Si no hay tests
```
⚠️  No se encontraron tests en el proyecto
    Baseline capturado con 0 tests
    Esto es normal para proyectos nuevos
```

### Si los tests fallan
```
❌ Tests fallaron durante baseline capture

   Tests que fallan:
   - auth.test.ts: 2 failures
   - course.test.ts: 1 failure

   ⚠️  ADVERTENCIA: El proyecto tiene tests rotos ANTES del cambio

   Opciones:
   1. Arreglar tests primero
   2. Continuar de todas formas (no recomendado)

   ¿Continuar con baseline con tests rotos? (y/n)
```

---

## 🔄 Uso en Workflows

Este skill se ejecuta SIEMPRE como PRIMERA FASE de cualquier workflow:

```
workflow feature "Nueva funcionalidad"
  ↓
FASE 0: 01-capture-baseline  ← Ejecuta este skill
  ↓
FASE 1: docker-wsl2-devops
  ↓
FASE 2: backend-implementor
  ...
```

---

## 📝 Notas

- Usar herramienta **Bash** para ejecutar comandos
- Usar herramienta **Read** para leer package.json
- Usar herramienta **Write** para crear baseline.json
- Guardar output completo en `.checkpoints/00-baseline-capture.log`
- Ser verboso en el output para debugging

---

**Duración estimada:** 3-5 minutos (depende del tamaño de la suite de tests)
