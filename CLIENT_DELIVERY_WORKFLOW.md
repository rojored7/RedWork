# Client Delivery Workflow

**Cómo usar el framework localmente y entregar al cliente SIN el framework**

---

## 🎯 El Concepto

```
┌────────────────────────────────────────────────────────────┐
│  TU ENTORNO LOCAL                                          │
│  ✅ Framework completo                                     │
│  ✅ Agentes, hooks, scripts                                │
│  ✅ Enforcement system                                     │
│  ✅ Documentación interna                                  │
│  ✅ Reports, validaciones                                  │
└────────────────────────────────────────────────────────────┘
                    ↓
            [git push origin main]
                    ↓
┌────────────────────────────────────────────────────────────┐
│  REPOSITORIO DEL CLIENTE (GitHub)                         │
│  ✅ Código de producción                                   │
│  ✅ Tests                                                   │
│  ✅ Configuraciones                                        │
│  ✅ README.md                                              │
│  ❌ SIN framework                                          │
│  ❌ SIN .claude/                                           │
│  ❌ SIN scripts internos                                   │
│  ❌ SIN documentación interna                              │
└────────────────────────────────────────────────────────────┘
```

**Analogía**: El framework es el **andamio**. Lo usas para construir el edificio, pero no se lo entregas al cliente.

---

## 📋 Setup Inicial de Proyecto

### Step 1: Crear Nuevo Proyecto para Cliente

```bash
# 1. Crear directorio del proyecto
mkdir proyecto-cliente
cd proyecto-cliente

# 2. Inicializar git
git init

# 3. Copiar .gitignore PARA CLIENTE
cp C:/Users/Itac/Proyectos/Framework/.gitignore-CLIENT-DELIVERY ./.gitignore

# 4. Copiar framework LOCALMENTE (NO se versionará)
cp -r C:/Users/Itac/Proyectos/Framework/.claude/ ./.claude/
cp -r C:/Users/Itac/Proyectos/Framework/scripts/ ./scripts/
cp -r C:/Users/Itac/Proyectos/Framework/.husky/ ./.husky/

# 5. Instalar hooks LOCALMENTE
bash scripts/install-git-hooks.sh

# 6. Verificar qué se versionará
git status

# DEBE MOSTRAR:
# .gitignore (nuevo)
# README.md (si existe)
#
# NO DEBE MOSTRAR:
# .claude/ (ignorado)
# scripts/ (ignorado)
# .husky/ (ignorado)
```

---

### Step 2: Verificar Framework NO se Versionará

```bash
# Verificar .gitignore está bloqueando framework
cat .gitignore | grep ".claude"
# Debe mostrar: .claude/

# Verificar git ignora framework
git status

# NO debe mostrar:
# - .claude/
# - scripts/hooks/
# - .husky/
# - Framework docs

# Crear commit de prueba
echo "# Proyecto Cliente" > README.md
git add .
git commit -m "chore: Initial commit"

# Verificar qué está en git
git ls-files

# Debe mostrar SOLO:
# .gitignore
# README.md
#
# NO debe mostrar framework
```

---

## 🔄 Workflow Diario de Desarrollo

### Desarrollo Local (CON Framework)

```bash
# 1. Trabajas normalmente
cd proyecto-cliente

# 2. Framework está ACTIVO localmente
ls .claude/  # ✅ Existe
ls scripts/  # ✅ Existe

# 3. Agentes usan el framework
# Los agentes leen .claude/AUTOMATIC_HOOK_ENFORCEMENT.md
# Los agentes ejecutan PRE-HOOK y POST-HOOK
# Validación 100% garantizada

# 4. Desarrollas features
# Backend: backend/src/modules/...
# Frontend: frontend/src/...
# Tests: backend/src/**/*.spec.ts

# 5. Git hooks validan ANTES de commit
git add backend/src/modules/auth/
git commit -m "feat: Add authentication module"

# Pre-commit hook ejecuta:
# ✅ Linting
# ✅ Compilation
# ✅ Tests
# ✅ Framework validation

# Si falla → commit BLOQUEADO
# Si pasa → commit OK
```

---

### Push al Cliente (SIN Framework)

```bash
# 1. Verificar qué se enviará al cliente
git status

# Debe mostrar SOLO código de producción:
# backend/src/
# frontend/src/
# package.json
# README.md
# etc.

# NO debe mostrar:
# .claude/ (ignorado por .gitignore)
# scripts/hooks/ (ignorado)
# Framework docs (ignorado)

# 2. Push normal
git push origin main

# 3. Verificar en GitHub
# Ir a: github.com/cliente/proyecto
# Debe mostrar SOLO código de producción
# NO debe ver .claude/, scripts/hooks/, etc.
```

---

## 📊 Qué Ve el Cliente vs Qué Tienes Localmente

### Tu Entorno Local

```
proyecto-cliente/
├── .claude/                           ← ✅ LOCAL (framework)
│   ├── agents/                        ← ✅ LOCAL (20 agentes)
│   ├── AUTOMATIC_HOOK_ENFORCEMENT.md  ← ✅ LOCAL
│   ├── agent-config.md                ← ✅ LOCAL
│   └── enforcement/                   ← ✅ LOCAL
│
├── scripts/                           ← ✅ LOCAL (framework)
│   ├── hooks/                         ← ✅ LOCAL
│   ├── enforce-sprint-baseline.sh     ← ✅ LOCAL
│   └── validate-*.sh                  ← ✅ LOCAL
│
├── .husky/                            ← ✅ LOCAL (framework)
│   ├── pre-commit                     ← ✅ LOCAL
│   └── pre-push                       ← ✅ LOCAL
│
├── backend/                           ← ✅ CLIENTE ve esto
│   └── src/                           ← ✅ CLIENTE ve esto
│
├── frontend/                          ← ✅ CLIENTE ve esto
│   └── src/                           ← ✅ CLIENTE ve esto
│
├── .gitignore                         ← ✅ CLIENTE ve esto
├── README.md                          ← ✅ CLIENTE ve esto
└── package.json                       ← ✅ CLIENTE ve esto
```

---

### Repositorio del Cliente (GitHub)

```
proyecto-cliente/ (GitHub)
├── backend/                           ← ✅ Código producción
│   └── src/
│
├── frontend/                          ← ✅ Código producción
│   └── src/
│
├── .gitignore                         ← ✅ Ignora secrets, node_modules
├── README.md                          ← ✅ Documentación proyecto
├── package.json                       ← ✅ Dependencies
└── docker-compose.yml                 ← ✅ Infrastructure

❌ NO EXISTE:
   .claude/                            ← Framework (no versionado)
   scripts/hooks/                      ← Framework (no versionado)
   .husky/                             ← Framework (no versionado)
   FRAMEWORK_*.md                      ← Docs internas (no versionadas)
```

---

## 🔧 Scripts Útiles

### Verificar Qué se Enviará al Cliente

```bash
# Ver qué archivos están trackeados en git
git ls-files

# Ver qué se enviaría en próximo push
git diff --stat origin/main

# Ver tamaño del repo (sin framework)
du -sh .git
```

---

### Limpiar Framework del Historial (Si se Comitió por Error)

```bash
# Si accidentalmente comiteaste el framework:

# 1. Remover del último commit
git reset HEAD~1
git add backend/ frontend/ package.json README.md
git commit -m "Previous message"

# 2. Remover de todo el historial (PELIGROSO)
git filter-branch --tree-filter 'rm -rf .claude scripts/.husky' HEAD

# 3. Force push (solo si no hay otros devs)
git push origin main --force
```

---

## 🎯 Workflow Recomendado para Equipos

### Setup: Repositorio Dual

Si trabajas en equipo, considera 2 repositorios:

#### Repositorio Interno (Privado)

```
proyecto-cliente-INTERNAL (GitHub privado)
├── .claude/                    ← Framework completo
├── scripts/                    ← Scripts de enforcement
├── .husky/                     ← Git hooks
├── backend/                    ← Código
├── frontend/                   ← Código
└── .project-orchestration/     ← Planning interno
```

**Para**: Desarrollo interno del equipo
**Incluye**: Framework completo, planning, reports
**Push**: Todo el equipo pushea aquí

---

#### Repositorio Cliente (Público/Cliente)

```
proyecto-cliente (GitHub del cliente)
├── backend/                    ← Solo código producción
├── frontend/                   ← Solo código producción
├── README.md                   ← Documentación
└── package.json                ← Dependencies
```

**Para**: Entrega al cliente
**Incluye**: SOLO código de producción
**Push**: Script automático sincroniza código (sin framework)

---

### Script de Sincronización

```bash
#!/bin/bash
# sync-to-client.sh
# Sincroniza código del repo interno al repo del cliente

set -e

echo "🔄 Syncing code to client repository..."

# Directorios
INTERNAL_REPO="."
CLIENT_REPO="../proyecto-cliente-DELIVERY"

# 1. Copiar solo código de producción
rsync -av --delete \
  --exclude='.claude' \
  --exclude='scripts/hooks' \
  --exclude='.husky' \
  --exclude='.project-orchestration' \
  --exclude='*_report.md' \
  --exclude='FRAMEWORK_*.md' \
  $INTERNAL_REPO/ $CLIENT_REPO/

# 2. Ir al repo del cliente
cd $CLIENT_REPO

# 3. Commit y push
git add .
git commit -m "sync: Update from internal development"
git push origin main

echo "✅ Synced to client repository"
```

---

## ✅ Checklist Antes de Entregar al Cliente

### Pre-Delivery Checklist

- [ ] ✅ Código de producción está completo
- [ ] ✅ Tests 100% pasando
- [ ] ✅ Linting clean (0 errors, 0 warnings)
- [ ] ✅ Build funciona (`npm run build`)
- [ ] ✅ Docker compose UP (si aplica)
- [ ] ✅ Smoke tests pasando
- [ ] ✅ README.md actualizado para cliente
- [ ] ✅ .env.example incluido (sin secrets)
- [ ] ❌ Framework NO está en git (`git ls-files | grep .claude` → vacío)
- [ ] ❌ Scripts internos NO están en git
- [ ] ❌ Reports NO están en git
- [ ] ❌ Documentación interna NO está en git

---

### Comandos de Verificación Final

```bash
# 1. Verificar framework NO está versionado
git ls-files | grep ".claude"
# Resultado esperado: (vacío)

git ls-files | grep "scripts/hooks"
# Resultado esperado: (vacío)

git ls-files | grep "FRAMEWORK"
# Resultado esperado: (vacío)

# 2. Verificar solo código está versionado
git ls-files | grep "backend/src"
# Resultado esperado: lista de archivos .ts

git ls-files | grep "frontend/src"
# Resultado esperado: lista de archivos .tsx, .ts

# 3. Verificar README para cliente existe
git ls-files | grep "README.md"
# Resultado esperado: README.md

# 4. Verificar tamaño del repo (debe ser pequeño)
du -sh .git
# Resultado esperado: <10 MB (sin framework)

# Si el .git es >50 MB → framework se comitió por error
```

---

## 🚨 Solución de Problemas

### Problema: Framework se Comitió por Error

**Síntomas**:
- `git ls-files | grep ".claude"` muestra archivos
- Repo es muy grande (>50 MB)
- Cliente puede ver `.claude/` en GitHub

**Solución 1: Si fue el último commit**
```bash
# Remover del último commit
git reset HEAD~1
git add backend/ frontend/ package.json README.md .gitignore
git commit -m "Same message as before"
git push origin main --force
```

**Solución 2: Si está en historial antiguo**
```bash
# Usar git filter-repo (más seguro que filter-branch)
pip install git-filter-repo

# Remover .claude/ de TODO el historial
git filter-repo --path .claude --invert-paths
git filter-repo --path scripts/hooks --invert-paths

# Force push
git push origin main --force
```

---

### Problema: Hooks No Funcionan Localmente

**Síntomas**:
- Commits pasan sin validación
- Framework existe pero no se ejecuta

**Solución**:
```bash
# Reinstalar hooks
bash scripts/install-git-hooks.sh

# Verificar hooks instalados
ls -la .git/hooks/pre-commit
ls -la .git/hooks/pre-push

# Deben ser ejecutables
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

---

## 📖 Resumen

### ✅ Desarrollo Local (TU)

```bash
proyecto/
├── .claude/        ← ✅ Framework (LOCAL, no versionado)
├── scripts/        ← ✅ Scripts (LOCAL, no versionado)
├── .husky/         ← ✅ Hooks (LOCAL, no versionado)
├── backend/src/    ← ✅ Código (VERSIONADO)
└── frontend/src/   ← ✅ Código (VERSIONADO)
```

**Git status muestra**: SOLO código (backend, frontend, configs)
**Git ignora**: Framework completo (.claude/, scripts/, .husky/)

---

### ✅ GitHub del Cliente

```bash
proyecto/ (GitHub)
├── backend/src/    ← ✅ Código producción
├── frontend/src/   ← ✅ Código producción
├── README.md       ← ✅ Documentación
└── package.json    ← ✅ Dependencies
```

**Cliente ve**: SOLO código de producción
**Cliente NO ve**: Framework, scripts internos, docs internas

---

### 🔑 Archivo Clave

**`.gitignore-CLIENT-DELIVERY`** hace todo esto posible:
- Bloquea TODA la carpeta `.claude/`
- Bloquea scripts internos
- Bloquea hooks
- Bloquea documentación interna
- SOLO permite código de producción

---

**Próximo paso**: Copiar `.gitignore-CLIENT-DELIVERY` como `.gitignore` en tu próximo proyecto de cliente.

