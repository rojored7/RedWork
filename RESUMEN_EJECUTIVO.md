# Framework - Resumen Ejecutivo

**Quality Enforcement Framework for Client Projects**

---

## 🎯 Qué Es

Sistema de 4 capas que garantiza 100% calidad de código mientras trabajas, pero **NO se entrega al cliente**.

Es como un **andamio**: Lo usas para construir, pero lo quitas antes de entregar.

---

## ✅ Problema que Resuelve

### ANTES (Sin Framework)

```
Agente reporta: "Sprint COMPLETE ✅ 100%"
Realidad:       Sprint 47% completo
                Tests: 25% passing
                Coverage: 61%
                E2E: Skipped

Resultado: Código roto llega a producción
```

### DESPUÉS (Con Framework)

```
Framework valida: PRE-HOOK antes de empezar
                 POST-HOOK después de terminar
                 Git hooks antes de commit

Resultado: Solo código 100% validado llega a producción
```

---

## 📁 Contenido

### 1. Agentes (agents/ - 20 agentes)
- 01-product-discovery → 20-linting-validator
- Workflow completo: Discovery → Design → Development → Testing → Security

### 2. Enforcement System (.claude/)
- AUTOMATIC_HOOK_ENFORCEMENT.md (reglas obligatorias)
- agent-config.md (configuraciones)
- enforcement/ (validadores de gates)
- validators/ (validadores backend/frontend)

### 3. Scripts (scripts/ - 30+ scripts)
- enforce-sprint-baseline.sh (validador de sprint)
- validate-*.sh (múltiples validadores)
- smoke-test-*.sh (smoke tests)
- hooks/ (post-wave hooks)

### 4. Git Hooks (.husky/)
- pre-commit (valida antes de commit)
- pre-push (valida antes de push)

---

## 🚀 Uso para Proyectos de Cliente

### Setup Rápido (1 minuto)

```bash
# Crear proyecto con framework
bash setup-client-project.sh nombre-proyecto-cliente

# ✅ Framework instalado LOCALMENTE (no versionado)
# ✅ .gitignore configurado para cliente
# ✅ Git hooks activos
# ✅ Listo para desarrollo
```

### Desarrollo Diario

```bash
# 1. Trabajas NORMALMENTE
cd proyecto-cliente

# 2. Framework ACTIVO localmente
# Agentes leen .claude/AUTOMATIC_HOOK_ENFORCEMENT.md
# Hooks validan antes de commit

# 3. Push SOLO código al cliente
git push origin main

# Cliente ve:
#   ✅ backend/src/
#   ✅ frontend/src/
#   ✅ Tests, README
#
# Cliente NO ve:
#   ❌ .claude/ (framework)
#   ❌ scripts/ (enforcement)
#   ❌ .husky/ (hooks)
```

### Resultado

```
TU MÁQUINA:
  .claude/          ← Framework (LOCAL, no versionado)
  scripts/          ← Scripts (LOCAL, no versionado)
  backend/src/      ← Código (VERSIONADO)

GITHUB CLIENTE:
  backend/src/      ← Solo código
  frontend/src/     ← Solo código
  README.md         ← Solo docs cliente
```

---

## 📊 Estadísticas

- **Total archivos**: 106 archivos
- **Tamaño**: 1.1 MB
- **Agentes**: 20 especializados
- **Scripts**: 30+ enforcement
- **Docs**: 15 archivos

---

## 📖 Documentación Clave

### Para Empezar (5 min)
1. **START_HERE.md** - Entry point
2. **CLIENT_DELIVERY_WORKFLOW.md** - Workflow completo
3. **QUICK_START.md** - Setup rápido

### Referencia Completa
- **README.md** - Overview completo
- **AGENTS_SETUP.md** - Setup de agentes
- **WHAT_TO_COPY.md** - Qué copiar según caso
- **agents/README.md** - Documentación de agentes

### Avanzado
- **ROADMAP.md** - Layer 3 (CI/CD)
- **FRAMEWORK_COMPLETE.md** - Inventario completo

---

## ✅ Checklist de Uso

### Setup Inicial
- [ ] Correr `bash setup-client-project.sh nombre-proyecto`
- [ ] Verificar framework está LOCAL (`ls .claude/`)
- [ ] Verificar framework NO está en git (`git ls-files | grep .claude` → vacío)
- [ ] Verificar hooks funcionan (test commit)

### Desarrollo
- [ ] Agentes leen AUTOMATIC_HOOK_ENFORCEMENT.md
- [ ] PRE-HOOK ejecuta antes de trabajar
- [ ] POST-HOOK ejecuta después de terminar
- [ ] Git hooks bloquean commits malos

### Entrega al Cliente
- [ ] Solo código en git (`git ls-files`)
- [ ] Framework NO visible (`git ls-files | grep .claude` → vacío)
- [ ] README para cliente existe
- [ ] Tests 100% passing
- [ ] Linting clean

---

## 🎯 3 Opciones de Deployment

### Opción 1: Proyectos de Cliente (TU CASO)

**Usa**: `.gitignore-CLIENT-DELIVERY`

**Resultado**:
- Framework LOCAL (no versionado)
- Cliente solo ve código
- Push limpio sin framework

---

### Opción 2: Proyectos Internos de Equipo

**Usa**: `.gitignore-framework`

**Resultado**:
- Framework versionado
- Todo el equipo usa mismo framework
- Todos ven .claude/, scripts/

---

### Opción 3: Template para GitHub

**Usa**: Agentes versionados

**Resultado**:
- Framework público
- Otros pueden clonar
- Documentación completa incluida

---

## 🔑 Archivos Críticos

### Para Cliente (SIEMPRE usar)
- `.gitignore-CLIENT-DELIVERY` ← Ignora framework
- `setup-client-project.sh` ← Setup automático
- `CLIENT_DELIVERY_WORKFLOW.md` ← Workflow

### Para Entender Framework
- `START_HERE.md` ← Empieza aquí
- `AGENTS_SETUP.md` ← Por qué agentes locales
- `QUICK_START.md` ← Setup rápido

---

## ⚡ Quick Commands

```bash
# Crear proyecto para cliente
bash setup-client-project.sh mi-proyecto

# Verificar qué se enviará al cliente
git ls-files

# Verificar framework NO está versionado
git ls-files | grep ".claude"  # Debe estar vacío

# Push al cliente (solo código)
git push origin main
```

---

## 💡 Tip: Analogía del Andamio

```
ANDAMIO (Framework)          EDIFICIO (Tu Código)
├── .claude/                 ├── backend/src/
├── scripts/                 ├── frontend/src/
└── .husky/                  └── README.md

Durante construcción:        Al entregar:
✅ Andamio visible          ❌ Andamio removido
✅ Usas para construir      ✅ Solo edificio entregado
```

**Framework = Andamio**: Esencial para construir, pero no parte del producto final.

---

## 📞 Soporte

**Documentación completa**:
- `START_HERE.md` - Punto de entrada
- `CLIENT_DELIVERY_WORKFLOW.md` - Workflow detallado
- `README.md` - Overview completo

**Scripts útiles**:
- `setup-client-project.sh` - Setup automático
- `scripts/install-git-hooks.sh` - Instalar hooks

**Verificación**:
- `git ls-files` - Ver qué se versionará
- `git status` - Ver qué se commitará

---

**Versión**: 1.0.0
**Fecha**: 2026-03-31
**Propósito**: Framework interno, NO para clientes
**Modo**: Client Delivery (framework local, código versionado)
