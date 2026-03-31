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

**Regla:** Controllers solo pueden importar Services, NO directamente Repositories/Prisma

```typescript
// ❌ VIOLACIÓN
// backend/src/controllers/user.controller.ts
import { prisma } from '../utils/prisma';  // NO PERMITIDO

// ✅ CORRECTO
import { userService } from '../services/user.service';
```

**Verificación:**
```bash
# Buscar imports de prisma en controllers
grep -r "from.*prisma" backend/src/controllers/
```

### 3. Validar Naming Conventions

**Reglas:**
- Files: kebab-case (`user-service.ts`)
- Classes: PascalCase (`UserService`)
- Functions: camelCase (`getUserById`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRIES`)

**Verificación:**
```bash
# Buscar archivos que no sigan kebab-case
find backend/src -name "*[A-Z]*.ts"
```

### 4. Detectar Circular Dependencies

```bash
# Usar madge o similar para detectar ciclos
npx madge --circular backend/src/
```

### 5. Validar Import Order

**Orden esperado:**
1. Node builtins (`fs`, `path`)
2. External (`express`, `prisma`)
3. Internal (`@/services`, `@/utils`)
4. Relative (`./`, `../`)

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
   - notification-Service.ts (debe ser notification-service.ts)
   - NotificationUtils.ts (debe ser notification-utils.ts)

✅ Circular dependencies: Ninguna

⚠️  Import order: 3 violations
   - notification.controller.ts:5 (external after internal)
   - notification.service.ts:12 (relative before external)
   - useNotifications.ts:8 (wrong order)

⚠️  File organization: 1 violation
   - src/notificationHelper.ts (debe estar en utils/)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 CAS Validation: PASSED with warnings

⚠️  6 violations detectadas (modo advisory)
   - 2 naming
   - 3 import order
   - 1 file organization

💡 Recomendaciones:
1. Renombrar archivos a kebab-case
2. Reordenar imports (puedes usar: npm run lint:fix)
3. Mover notificationHelper.ts a utils/

ℹ️  Modo Advisory: No bloquea el workflow
   Puedes continuar, pero considera arreglar estos issues
```

---

## 🔧 Reglas Configurables

El proyecto puede definir reglas personalizadas en `.arch-rules.ts`:

```typescript
// .arch-rules.ts
export const rules = {
  layering: {
    controllers: {
      canImport: ['services', 'types', 'middleware'],
      cannotImport: ['repositories', 'utils/prisma']
    },
    services: {
      canImport: ['repositories', 'types', 'utils'],
      cannotImport: ['controllers', 'routes']
    }
  },
  naming: {
    files: 'kebab-case',
    classes: 'PascalCase',
    functions: 'camelCase'
  },
  maxFileSize: 300, // líneas
  maxComplexity: 10,
  noDefaultExports: true // excepto pages
};
```

---

## 🚨 Categorías de Violaciones

### Critical (Bloquean - pero NO en modo advisory)
- Circular dependencies
- Import de Prisma en Controllers
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
**File:** backend/src/services/notification-Service.ts
**Rule:** File names must be kebab-case
**Current:** notification-Service.ts
**Expected:** notification-service.ts
**Fix:** Rename file

### 2. Import Order
**File:** backend/src/controllers/notification.controller.ts
**Line:** 5
**Rule:** External imports must come before internal
**Current:**
```typescript
import { notificationService } from '@/services';
import express from 'express';  // ← Wrong order
```
**Expected:**
```typescript
import express from 'express';
import { notificationService } from '@/services';
```
**Fix:** Reorder imports (auto-fixable with ESLint)

[... más violaciones ...]

## Recommendations
1. Run `npm run lint:fix` to auto-fix import order
2. Rename files to kebab-case
3. Consider splitting large files (notification.service.ts: 315 LOC)

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
