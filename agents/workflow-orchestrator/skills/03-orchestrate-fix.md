# Skill: Orchestrate Fix Workflow

**Purpose:** Workflow rápido y automático para fixes y refactors
**Duration:** 10-20 minutos
**Mode:** Automático (sin pausas, ejecuta todo de corrido)
**Critical:** Moderado

---

## 🎯 Objetivo

Implementar un fix o refactor de manera rápida, con regression testing automático, pero SIN checkpoints de aprobación manual (workflow automático).

**Diferencia con orchestrate-feature:**
- ❌ Sin pausas entre fases
- ❌ Sin preguntas de aprobación
- ✅ Ejecuta todo automáticamente
- ✅ Solo bloquea si regression falla

---

## 📋 Fases del Workflow

```
FASE 0: Baseline Capture (automático)
   ↓
FASE 1: Docker (solo si necesario, automático)
   ↓
FASE 2: Backend (automático)
   ↓
FASE 3: Frontend (automático)
   ↓
FASE 4: Regression Testing ⚠️
   ├─ ✅ Pasa → Auto-aprobar
   └─ ❌ Falla → BLOQUEAR + reportar
```

---

## 🚀 Implementación

### FASE 0: Baseline
```markdown
Ejecutar skill: 01-capture-baseline
(Sin esperar aprobación)
```

### FASE 1: Docker (Condicional)
**Solo si la descripción menciona:**
- "migración"
- "base de datos"
- "docker"

```markdown
Invocar: docker-wsl2-devops
Prompt corto: "Fix: {DESCRIPTION}. Solo cambios de infra necesarios."
```

### FASE 2: Backend
```markdown
Invocar: backend-implementor

Prompt:
"MODO FIX - Implementación rápida
Tarea: {DESCRIPTION}
Contexto: {Checkpoint docker si existe}

Solo:
1. Archivos que necesiten modificación
2. Tests mínimos (si es fix de bug, test que demuestre el fix)
3. Sin documentation extensa

Guarda resumen en: .checkpoints/02-backend.md"
```

### FASE 3: Frontend
```markdown
Invocar: frontend-builder

Prompt:
"MODO FIX - Implementación rápida
Tarea: {DESCRIPTION}
Contexto backend: {.checkpoints/02-backend.md}

Solo:
1. Componentes/hooks que necesiten cambio
2. Tests básicos
3. Sin Storybook

Guarda resumen en: .checkpoints/03-frontend.md"
```

### FASE 4: Regression
```markdown
Ejecutar skill: 04-run-regression

Si pasa:
  ✅ Auto-aprobar workflow
  Mostrar resumen

Si falla:
  ❌ BLOQUEAR
  Reportar issues
  Pedir corrección
```

---

## 📊 Output Esperado

```
🔧 Fix Workflow - Modo Automático
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Fix: Corregir bug en cálculo de progreso

⚡ Ejecutando automáticamente...

📸 FASE 0: Baseline
   ✅ Capturado (156/156 tests)

📦 FASE 2: Backend
   ✅ Modificado: progress_service.py
   ✅ Test agregado: test_progress_calculation.py

🎨 FASE 3: Frontend
   ✅ Modificado: ProgressBar.tsx
   ✅ Test actualizado: ProgressBar.test.tsx

🔄 FASE 4: Regression
   ✅ 158/158 tests passed (+2 nuevos)
   ✅ REGRESSION PASSED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Fix completado exitosamente

Cambios:
- 2 archivos modificados
- 2 tests agregados
- 0 tests rotos
- Duración: 8 minutos

Checkpoints: .checkpoints/
```

---

## 🚨 Si Regression Falla

```
❌ Fix workflow BLOQUEADO

Regression detectó 2 tests rotos:
- enrollment.test.ts: calculation mismatch

El fix rompió funcionalidad existente.

Acciones:
1. Revisar: .checkpoints/02-backend.md
2. Corregir el issue
3. Re-ejecutar workflow

No auto-aprobado - requiere corrección.
```

---

## 💡 Cuándo Usar Este Workflow

**Usar orchestrate-fix para:**
- ✅ Bug fixes pequeños
- ✅ Refactors que no cambian funcionalidad
- ✅ Hotfixes urgentes
- ✅ Mejoras de performance
- ✅ Code cleanup

**NO usar para:**
- ❌ Features nuevas (usar orchestrate-feature)
- ❌ Cambios grandes de arquitectura
- ❌ Cambios que afectan múltiples módulos

---

**Duración estimada:** 10-20 minutos
**Mode:** Automático (sin pausas)
