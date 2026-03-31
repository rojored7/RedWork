# What to Copy to Each Project - Framework Deployment Guide

**TL;DR**: NO tienes que copiar TODO a cada proyecto. Solo lo esencial.

---

## 🎯 Quick Answer

### ✅ SÍ Copiar (y versionar en git)

```bash
.claude/
  ├── AUTOMATIC_HOOK_ENFORCEMENT.md  ← ✅ CRÍTICO: versionar
  ├── agent-config.md                ← ✅ CRÍTICO: versionar
  ├── enforcement/                   ← ✅ CRÍTICO: versionar
  └── validators/                    ← ✅ CRÍTICO: versionar

scripts/                             ← ✅ CRÍTICO: versionar
  ├── install-git-hooks.sh
  ├── enforce-sprint-baseline.sh
  └── ... (todos los scripts)

.husky/                              ← ✅ CRÍTICO: versionar
  ├── pre-commit
  └── pre-push

.gitignore                           ← ✅ CRÍTICO: versionar (anti-report rules)
```

**Tamaño total**: ~200 KB (scripts + enforcement + hooks)

---

### ⚙️ Agentes: 3 Opciones

#### Opción 1: Agentes Versionados (RECOMENDADO para equipos)

```bash
.claude/agents/                      ← ✅ Versionar en git
  ├── 01-product-discovery.md
  ├── 10-backend-fastapi-dev.md
  └── ... (20 agentes)
```

**Ventajas**:
- ✅ Todo el equipo usa los mismos agentes
- ✅ Cambios a agentes se trackean en git
- ✅ Fácil onboarding de nuevos devs

**Desventajas**:
- ❌ Agrega ~230 KB al repo
- ❌ Cambios en agentes requieren commits

**Cuándo usar**: Equipos con múltiples desarrolladores

---

#### Opción 2: Agentes NO Versionados (Cada dev los copia)

```bash
# En .gitignore:
.claude/agents/                      ← ❌ NO versionar

# Cada dev copia localmente:
cp Framework/agents/ proyecto/.claude/agents/
```

**Ventajas**:
- ✅ Repo más liviano
- ✅ Cada dev puede customizar sus agentes

**Desventajas**:
- ❌ Cada dev debe copiar manualmente
- ❌ No hay consistencia entre devs
- ❌ Difícil onboarding

**Cuándo usar**: Proyectos personales o devs con preferencias propias

---

#### Opción 3: Híbrido (Solo README versionado)

```bash
# Versionar:
.claude/agents/README.md             ← ✅ Versionar
.claude/agents/AGENTS_INDEX.md       ← ✅ Versionar

# NO versionar:
.claude/agents/*.md                  ← ❌ NO versionar (agentes individuales)

# .gitignore:
.claude/agents/*.md
!.claude/agents/README.md
!.claude/agents/AGENTS_INDEX.md
```

**Ventajas**:
- ✅ Documentación versionada (qué agentes usar)
- ✅ Repo liviano
- ✅ Cada dev copia agentes que necesita

**Desventajas**:
- ❌ Requiere README bien mantenido
- ❌ Cada dev copia manualmente

**Cuándo usar**: Equipos que quieren flexibilidad con documentación

---

### ❌ NO Copiar (personal, no versionar)

```bash
.claude/settings.local.json          ← ❌ Personal, no versionar
.claude/preferences.json             ← ❌ Personal, no versionar
.claude/.cache/                      ← ❌ Temporal, no versionar
```

---

## 📊 Comparativa de Opciones

| Aspecto | Opción 1<br>(Agentes Versionados) | Opción 2<br>(Agentes NO Versionados) | Opción 3<br>(Híbrido) |
|---------|-----------------------------------|---------------------------------------|----------------------|
| **Tamaño repo** | +230 KB | +0 KB | +20 KB (solo README) |
| **Consistencia equipo** | ✅ Muy alta | ❌ Baja | ⚙️ Media |
| **Onboarding** | ✅ Fácil (git clone) | ❌ Manual | ⚙️ Semi-manual |
| **Flexibilidad dev** | ❌ Baja | ✅ Alta | ✅ Alta |
| **Mantenimiento** | ⚙️ Git commits | ✅ Ninguno | ⚙️ README |
| **Recomendado para** | Equipos | Proyectos personales | Equipos flexibles |

---

## 🚀 Instrucciones de Deployment

### Para Equipos (Opción 1 - Agentes Versionados)

```bash
cd tu-proyecto/

# 1. Copiar TODO (incluyendo agentes)
cp -r C:/Users/Itac/Proyectos/Framework/.claude/ ./.claude/
cp -r C:/Users/Itac/Proyectos/Framework/scripts/ ./scripts/
cp -r C:/Users/Itac/Proyectos/Framework/.husky/ ./.husky/
cp C:/Users/Itac/Proyectos/Framework/.gitignore-framework ./.gitignore

# 2. Editar .gitignore para INCLUIR agentes
# Descomentar línea:
# !.claude/agents/

# 3. Git add
git add .claude/ scripts/ .husky/ .gitignore

# 4. Commit
git commit -m "chore: Add quality enforcement framework with agents

- Add AUTOMATIC_HOOK_ENFORCEMENT.md
- Add 20 specialized agents
- Add enforcement scripts and validators
- Add git hooks (pre-commit, pre-push)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

# 5. Cada dev instala hooks localmente
bash scripts/install-git-hooks.sh
```

**Tamaño del commit**: ~500 KB (framework + agentes)

---

### Para Proyectos Personales (Opción 2 - Agentes NO Versionados)

```bash
cd tu-proyecto/

# 1. Copiar framework SIN agentes
cp -r C:/Users/Itac/Proyectos/Framework/.claude/ ./.claude/
cp -r C:/Users/Itac/Proyectos/Framework/scripts/ ./scripts/
cp -r C:/Users/Itac/Proyectos/Framework/.husky/ ./.husky/
cp C:/Users/Itac/Proyectos/Framework/.gitignore-framework ./.gitignore

# 2. Borrar agentes del versionado
rm -rf .claude/agents/

# 3. Editar .gitignore para EXCLUIR agentes
# Asegurar que existe:
# .claude/agents/

# 4. Git add (sin agentes)
git add .claude/ scripts/ .husky/ .gitignore

# 5. Commit
git commit -m "chore: Add quality enforcement framework (without agents)

- Add AUTOMATIC_HOOK_ENFORCEMENT.md
- Add enforcement scripts and validators
- Add git hooks (pre-commit, pre-push)
- Agents must be copied locally by each dev

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

# 6. Copiar agentes LOCALMENTE (no versionado)
cp -r C:/Users/Itac/Proyectos/Framework/agents/ ./.claude/agents/

# 7. Instalar hooks
bash scripts/install-git-hooks.sh
```

**Tamaño del commit**: ~270 KB (framework sin agentes)

**Nota**: Agrega instrucciones en README para que otros devs copien agentes localmente.

---

### Para Equipos Flexibles (Opción 3 - Híbrido)

```bash
cd tu-proyecto/

# 1. Copiar framework + agentes
cp -r C:/Users/Itac/Proyectos/Framework/.claude/ ./.claude/
cp -r C:/Users/Itac/Proyectos/Framework/scripts/ ./scripts/
cp -r C:/Users/Itac/Proyectos/Framework/.husky/ ./.husky/
cp C:/Users/Itac/Proyectos/Framework/.gitignore-framework ./.gitignore

# 2. Editar .gitignore para modo híbrido
# Descomentar líneas:
# .claude/agents/*.md
# !.claude/agents/README.md
# !.claude/agents/AGENTS_INDEX.md

# 3. Git add (solo README de agentes)
git add .claude/ scripts/ .husky/ .gitignore

# 4. Commit
git commit -m "chore: Add quality enforcement framework (hybrid mode)

- Add AUTOMATIC_HOOK_ENFORCEMENT.md
- Add enforcement scripts and validators
- Add git hooks (pre-commit, pre-push)
- Add agent documentation (agents copied locally by devs)

See .claude/agents/README.md for agent setup instructions.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

# 5. Copiar agentes LOCALMENTE
cp -r C:/Users/Itac/Proyectos/Framework/agents/ ./.claude/agents/

# 6. Instalar hooks
bash scripts/install-git-hooks.sh
```

**Tamaño del commit**: ~290 KB (framework + README de agentes)

---

## 📋 Checklist Post-Deployment

Después de copiar el framework, verifica:

### Para Todos (Independiente de la opción)

- [ ] `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` existe
- [ ] `.claude/agent-config.md` existe
- [ ] `.claude/enforcement/` existe
- [ ] `.claude/validators/` existe
- [ ] `scripts/` existe con ~30 scripts
- [ ] `.husky/pre-commit` existe
- [ ] `.husky/pre-push` existe
- [ ] `.gitignore` tiene reglas anti-report
- [ ] Hooks instalados: `bash scripts/install-git-hooks.sh`
- [ ] Hooks funcionan: test commit debe mostrar validación

### Adicional para Opción 1 (Agentes Versionados)

- [ ] `.claude/agents/` existe con 20 agentes
- [ ] `.gitignore` NO ignora `.claude/agents/`
- [ ] `git status` muestra agentes como tracked
- [ ] Agentes están en git: `git ls-files .claude/agents/`

### Adicional para Opción 2 (Agentes NO Versionados)

- [ ] `.claude/agents/` existe LOCALMENTE
- [ ] `.gitignore` SÍ ignora `.claude/agents/`
- [ ] `git status` NO muestra agentes
- [ ] README documenta cómo copiar agentes

### Adicional para Opción 3 (Híbrido)

- [ ] `.claude/agents/README.md` está versionado
- [ ] `.claude/agents/*.md` (agentes) NO están versionados
- [ ] `git ls-files .claude/agents/` solo muestra README

---

## 🎯 Recomendaciones

### Equipos Grandes (5+ desarrolladores)
→ **Opción 1** (Agentes Versionados)
- Consistencia es crítica
- Onboarding frecuente
- Vale la pena +230 KB

### Equipos Pequeños (2-4 desarrolladores)
→ **Opción 3** (Híbrido)
- Balance entre consistencia y flexibilidad
- Documentación versionada
- Cada dev copia lo que necesita

### Proyectos Personales
→ **Opción 2** (Agentes NO Versionados)
- Repo minimalista
- Total flexibilidad
- No hay equipo que sincronizar

### Proyectos Open Source
→ **Opción 1** (Agentes Versionados)
- Contribuidores necesitan consistencia
- Fácil setup para nuevos contribuidores
- Transparencia total

---

## 📖 Documentación a Incluir en Proyecto

Independiente de la opción, agrega al README del proyecto:

```markdown
## Quality Enforcement Framework

This project uses a 4-layer quality enforcement framework:

1. **Layer 1**: Agent enforcement via `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md`
2. **Layer 2**: Git hooks via `.husky/` (pre-commit, pre-push)
3. **Layer 3**: CI/CD via GitHub Actions (TO BE IMPLEMENTED)
4. **Layer 4**: Documentation

### Setup for New Developers

\```bash
# 1. Clone repository
git clone <repo-url>

# 2. Install dependencies
npm install

# [OPCIÓN 1] Agentes ya versionados - nada más que hacer

# [OPCIÓN 2] Copiar agentes localmente
cp -r path/to/Framework/agents/ ./.claude/agents/

# [OPCIÓN 3] Copiar agentes que necesites
# Ver .claude/agents/README.md para lista completa

# 3. Install git hooks
bash scripts/install-git-hooks.sh

# 4. Verify setup
git add README.md
git commit -m "test"  # Should run pre-commit validation
\```

### Framework Enforcement

- ✅ Pre-commit: Validates code before commits (compilation, linting, tests)
- ✅ Pre-push: Validates sprint baseline before pushes (100% quality)
- ✅ POST-HOOK: Agents run validation after completing work

See `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` for details.
```

---

## ✅ Summary

| Qué | Versionar | Tamaño | Cuándo |
|-----|-----------|--------|--------|
| **Enforcement (.claude/)** | ✅ SÍ | ~50 KB | Siempre |
| **Scripts** | ✅ SÍ | ~135 KB | Siempre |
| **Hooks (.husky/)** | ✅ SÍ | ~5 KB | Siempre |
| **Gitignore** | ✅ SÍ | ~5 KB | Siempre |
| **Agentes** | ⚙️ Depende | ~230 KB | Opción 1: SÍ<br>Opción 2: NO<br>Opción 3: Solo README |
| **Docs** | ⚙️ Opcional | ~80 KB | Recomendado |

**Mínimo absoluto**: ~200 KB (sin agentes, sin docs)
**Recomendado para equipos**: ~500 KB (con agentes versionados)
**Recomendado para personal**: ~200 KB + agentes locales

---

**Siguiente paso**: Decide qué opción usar y sigue las instrucciones de deployment arriba.
