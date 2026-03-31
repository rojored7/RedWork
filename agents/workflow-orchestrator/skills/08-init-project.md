# Skill: Init Project

**Purpose:** Inicializar un proyecto nuevo con el sistema de workflows
**Duration:** 5-10 minutos
**Critical:** Alta (setup inicial)

---

## 🎯 Objetivo

Preparar un proyecto para usar el sistema de workflows completo:
1. Detectar tipo de proyecto
2. Copiar templates necesarios
3. Crear estructura de directorios
4. Configurar git hooks (opcional)
5. Capturar baseline inicial
6. Mostrar instrucciones de uso

---

## 📋 Proceso

### 1. Detectar Proyecto

```bash
# Verificar que estamos en un proyecto válido
if [ ! -f "package.json" ] && [ ! -f "requirements.txt" ]; then
  echo "❌ No es un proyecto Node.js ni Python"
  exit 1
fi
```

**Detectar frameworks:**
```json
// Leer package.json
{
  "dependencies": {
    "express": "^4.18.0",    // → Backend: Express
    "react": "^18.2.0"        // → Frontend: React
  },
  "devDependencies": {
    "jest": "^29.7.0",        // → Test runner: Jest
    "@playwright/test": "^1.40.0"  // → E2E: Playwright
  }
}
```

### 2. Crear Estructura de Directorios

```bash
# Crear directorios necesarios
mkdir -p .baselines
mkdir -p .checkpoints
mkdir -p reports/visual
mkdir -p reports/coverage
mkdir -p reports/consolidated

echo "✅ Directorios creados"
```

### 3. Copiar Templates

Del agente workflow-orchestrator copiar templates al proyecto:

#### 3.1: Smoke Tests Template

Si es Node.js con Jest:
```bash
# Copiar template de smoke tests
cp ~/.claude/agents/workflow-orchestrator/templates/smoke-tests.test.ts \
   backend/src/__tests__/regression/smoke-tests.test.ts
```

#### 3.2: Architecture Rules

```bash
# Copiar reglas de arquitectura
cp ~/.claude/agents/workflow-orchestrator/templates/.arch-rules.ts \
   ./.arch-rules.ts

# Si tiene backend separado
cp ~/.claude/agents/workflow-orchestrator/templates/.arch-rules.ts \
   backend/.arch-rules.ts
```

#### 3.3: Workflow Config

Crear `.workflow-config.json`:
```json
{
  "version": "1.0",
  "project": {
    "type": "nodejs",
    "backend": {
      "framework": "express",
      "testRunner": "jest",
      "path": "backend/"
    },
    "frontend": {
      "framework": "react",
      "testRunner": "vitest",
      "path": "frontend/"
    },
    "e2e": {
      "framework": "playwright",
      "path": "e2e/"
    }
  },
  "workflows": {
    "regression": {
      "enabled": true,
      "blockOnFailure": true
    },
    "architecture": {
      "enabled": true,
      "mode": "advisory"
    },
    "visual": {
      "enabled": true,
      "baselinesPath": "e2e/visual-regression/baselines/"
    }
  },
  "thresholds": {
    "minCoverage": 70,
    "maxRegressionFailures": 0,
    "maxArchViolations": 5
  }
}
```

#### 3.4: Makefile Helper

Crear `Makefile.workflow`:
```makefile
# Makefile helper for workflow commands
# Include this in your main Makefile

.PHONY: workflow-feature workflow-fix workflow-baseline workflow-regression

workflow-feature:
	@echo "Ejecutando workflow para feature..."
	@echo "Invoca al agente workflow-orchestrator con: workflow feature"

workflow-fix:
	@echo "Ejecutando workflow para fix..."
	@echo "Invoca al agente workflow-orchestrator con: workflow fix"

workflow-baseline:
	@echo "Capturando baseline..."
	@echo "Invoca al agente workflow-orchestrator con skill: 01-capture-baseline"

workflow-regression:
	@echo "Ejecutando regression..."
	@echo "Invoca al agente workflow-orchestrator con skill: 04-run-regression"
```

### 4. Actualizar .gitignore

Agregar entradas:
```bash
# Agregar a .gitignore
cat >> .gitignore << 'EOF'

# Workflow System
.baselines/
.checkpoints/
reports/
temp-*-results.json

# Visual regression baselines (opcional - commitear si quieres)
# e2e/visual-regression/baselines/
EOF

echo "✅ .gitignore actualizado"
```

### 5. Instalar Dependencias (Opcional)

```bash
# Si no existen, sugerir instalar
if ! npm list ts-arch >/dev/null 2>&1; then
  echo "📦 Instalando dependencias de validación..."
  npm install --save-dev ts-arch @typescript-eslint/eslint-plugin
fi
```

### 6. Organizar Tests por Features

```bash
# Crear estructura de tests por features
mkdir -p backend/src/__tests__/features
mkdir -p backend/src/__tests__/regression

echo "📁 Estructura de tests creada"
```

### 7. Capturar Baseline Inicial

```markdown
Ejecutar skill: 01-capture-baseline

Esto captura el estado inicial del proyecto para futuras comparaciones.
```

### 8. Generar Documentación

Crear `.workflow-guide.md`:
```markdown
# Guía de Workflow System

Este proyecto usa el **workflow-orchestrator agent** para desarrollo.

## Comandos Disponibles

### Implementar Feature Nueva
\`\`\`
En chat con Claude:
"Implementar sistema de notificaciones"

Claude ejecutará automáticamente:
- Captura baseline
- Coordina agentes (docker, backend, frontend)
- Ejecuta regression testing
- Valida arquitectura
- Verificación visual
\`\`\`

### Implementar Fix Rápido
\`\`\`
En chat con Claude:
"Corregir bug en cálculo de progreso"

Claude ejecutará workflow automático (sin pausas)
\`\`\`

### Capturar Baseline Manual
\`\`\`
"Captura baseline del proyecto"
\`\`\`

### Ejecutar Regression Manual
\`\`\`
"Ejecuta regression testing"
\`\`\`

## Estructura de Archivos

\`\`\`
project/
├── .baselines/          # Baselines de regression
├── .checkpoints/        # Estado de workflows
├── reports/             # Reportes de tests/visual
└── .workflow-config.json  # Configuración
\`\`\`

## Flujo Típico

1. Trabajas en feature
2. Dices: "Implementar [feature]"
3. Claude captura baseline
4. Claude coordina agentes
5. Claude ejecuta regression
6. Si pasa → apruebas
7. Si falla → Claude reporta qué se rompió

## Regression Testing

⚠️ **CRÍTICO**: Después de cada cambio, el sistema ejecuta TODOS los tests.

Si algún test viejo se rompe → Workflow BLOQUEADO

Esto previene bugs en producción.
\`\`\`

---

## 📊 Output Esperado

```
🎬 Inicializando proyecto con Workflow System...

📍 Proyecto detectado:
   Tipo: Node.js
   Backend: Express (Jest)
   Frontend: React (Vitest)
   E2E: Playwright

📁 Creando estructura...
   ✅ .baselines/
   ✅ .checkpoints/
   ✅ reports/

📄 Copiando templates...
   ✅ smoke-tests.test.ts
   ✅ .arch-rules.ts
   ✅ .workflow-config.json
   ✅ Makefile.workflow

🔧 Configurando .gitignore...
   ✅ Entradas agregadas

📦 Dependencias...
   ✅ ts-arch instalado
   ℹ️  Otras dependencias ya presentes

📸 Capturando baseline inicial...
   ✅ Tests: 156/156 passed
   ✅ Coverage: Backend 82%, Frontend 76%
   ✅ Baseline guardado

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Proyecto inicializado exitosamente!

📚 Guía de uso: .workflow-guide.md

Ahora puedes:
- "Implementar [feature]" → Workflow completo
- "Corregir [bug]" → Workflow rápido
- "Ejecuta regression" → Solo testing

El sistema garantiza que NADA se rompa con tus cambios.

Baseline inicial: .baselines/latest.json
```

---

## 🎓 Instrucciones Post-Instalación

Después de init, mostrar:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎓 Cómo usar el Workflow System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

En tu chat con Claude, simplemente di:

1. Para implementar feature:
   "Implementar sistema de notificaciones push"

2. Para fix rápido:
   "Corregir bug en el login"

3. Para capturar baseline:
   "Captura baseline del proyecto"

4. Para ejecutar regression:
   "Ejecuta regression completo"

Claude detectará automáticamente la intención y
ejecutará el workflow apropiado.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Tip: Siempre captura baseline ANTES de empezar
        a trabajar en algo nuevo.

⚠️  Importante: Si regression falla, significa que
        algo se rompió. NO ignorar esas alertas.
```

---

## 🔄 Re-Inicialización

Si el proyecto ya tiene workflow:

```
⚠️  Proyecto ya inicializado

Configuración existente detectada:
- .workflow-config.json
- .baselines/latest.json

¿Qué deseas hacer?
1. Actualizar templates
2. Re-capturar baseline
3. Regenerar documentación
4. Cancelar

Opción: _
```

---

## 📝 Validación Post-Init

```bash
# Verificar que todo está configurado
echo "✅ Verificando setup..."

# Check dirs
[ -d ".baselines" ] && echo "  ✅ .baselines/"
[ -d ".checkpoints" ] && echo "  ✅ .checkpoints/"

# Check files
[ -f ".workflow-config.json" ] && echo "  ✅ .workflow-config.json"
[ -f "backend/src/__tests__/regression/smoke-tests.test.ts" ] && echo "  ✅ smoke-tests.test.ts"

# Check baseline
[ -f ".baselines/latest.json" ] && echo "  ✅ Baseline inicial capturado"

echo ""
echo "🎉 Setup completo y validado!"
```

---

**Duración estimada:** 5-10 minutos
**Requiere:** Proyecto con package.json
**One-time:** Solo se ejecuta una vez por proyecto
