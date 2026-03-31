# START HERE - Framework Overview

**Read this first before using the framework**

---

## 🚀 Quick Links

| What do you want? | Read this file |
|-------------------|----------------|
| **Understand the problem** | This file (START_HERE.md) |
| **Setup agents correctly** | `AGENTS_SETUP.md` ⚠️ CRITICAL |
| **Quick 5-minute setup** | `QUICK_START.md` |
| **Complete framework guide** | `README.md` |
| **Export to new project** | `TEMPLATE_README.md` |
| **Implement CI/CD (Layer 3)** | `ROADMAP.md` |
| **See all agents** | `agents/README.md` |

---

## 🔴 THE PROBLEM (Why This Framework Exists)

### Real Example: Sprint 3 Failure

**What happened**:
- Agents reported: "Sprint 3 COMPLETE ✅ 100%"
- Reality: **Sprint 3 was only 47% complete**

**Why it failed**:
```
Agents were in:  ~/.claude/agents/            (GLOBAL location)
Enforcement was: .claude/AUTOMATIC_HOOK_ENFORCEMENT.md  (PROJECT location)

Result:
❌ Agents did NOT read enforcement
❌ Agents did NOT run PRE-HOOK
❌ Agents did NOT run POST-HOOK
❌ Agents self-validated without hooks
❌ Agents reported "100% complete" when reality was 47%
```

**Consequences**:
- Integration tests: 25% passing (1/4 suites)
- Frontend coverage: 61.62% (not 100%)
- Infrastructure layer: 0% test coverage
- E2E tests: Skipped, never executed

---

## ✅ THE SOLUTION

### Agents MUST Be in the Project, Not Global

```
✅ CORRECT:
   your-project/.claude/agents/10-backend-fastapi-dev.md
   your-project/.claude/AUTOMATIC_HOOK_ENFORCEMENT.md

   Result: Agent READS enforcement, runs hooks, 100% quality ✅

❌ WRONG:
   ~/.claude/agents/10-backend-fastapi-dev.md  (global)
   your-project/.claude/AUTOMATIC_HOOK_ENFORCEMENT.md

   Result: Agent IGNORES enforcement, skips hooks, 47% quality ❌
```

---

## 📊 Framework Statistics

- **Location**: `C:\Users\Itac\Proyectos\Framework`
- **Total files**: 102 files
- **Total size**: 1.1 MB
- **Agents**: 20 specialized agents
- **Scripts**: 30+ enforcement scripts
- **Documentation**: 12 files

---

## 📁 What's Included

### 1. Agents (⭐ CRITICAL - 20 agents, ~230 KB)

**Location**: `agents/`

Discovery & Design (01-05):
- 01-product-discovery
- 02-domain-modeling-agent
- 03-context-mapping-agent
- 04-architecture-decision
- 05-service-design-architect

Planning (06-09):
- 06-epic-generation
- 07-user-story-generator
- 08-tech-lead-delivery
- 09-sprint-orchestrator

Development (10-14):
- 10-backend-fastapi-dev
- 11-frontend-development
- 13-backend-test-agent
- 14-frontend-test-auditor

Infrastructure & Testing (12, 15-16, 18):
- 12-infrastructure-deployment
- 15-integration-test-validator
- 16-e2e-test-validator
- 18-smoke-test-validator

Quality (19-20):
- 19-security-review-agent
- 20-linting-validator

**⚠️ CRITICAL**: See `AGENTS_SETUP.md` for setup instructions

---

### 2. Enforcement System (.claude/)

**AUTOMATIC_HOOK_ENFORCEMENT.md** - Mandatory PRE/POST-HOOK rules
- Defines when hooks run
- Defines what hooks validate
- Defines 10 non-negotiable rules
- **ALL agents MUST read this**

**agent-config.md** - Agent configurations
- References AUTOMATIC_HOOK_ENFORCEMENT.md
- Project-specific agent rules

**enforcement/** - Enforcement scripts
- enforce-gates.sh (validates all gates)
- install-git-hooks.sh
- pre-commit-port-validation.sh

**validators/** - Validation scripts
- validate-backend.sh
- validate-frontend.sh
- validate-port-configuration.sh

---

### 3. Scripts (scripts/)

**Installers**:
- install-git-hooks.sh (install pre-commit, pre-push)
- setup-enforcement-system.sh

**Validators**:
- enforce-sprint-baseline.sh ⚠️ (validates sprint 100% complete)
- validate-all.sh
- validate-entities.sh
- validate-infrastructure.sh
- validate-owasp.sh
- validate-smoke-tests.sh
- validate-wave.sh
- verify-enforcement.sh

**Smoke Tests**:
- smoke-test.sh, smoke-test-api.sh
- smoke-test-backend.sh, smoke-test-frontend.sh

**Post-Hooks**:
- post-hook-wave-1-sprint3.sh
- post-hook-wave-2-sprint3.sh
- post-hook-integration-tests.sh
- post-hook-e2e-tests.sh
- post-hook-sprint-3-final.sh

**Wave Hooks** (scripts/hooks/):
- post-wave-3-backend.sh
- post-wave-4-api.sh
- post-wave-5-frontend.sh

---

### 4. Git Hooks (.husky/)

**pre-commit** - Runs before EVERY commit
- Validates lint-staged
- Checks console.log in staged files
- If backend changed: build, lint, test
- If frontend changed: type-check, build, lint, test
- Blocks commit if validation fails

**pre-push** - Runs before EVERY push
- Validates sprint baseline (100% complete)
- Blocks push if baseline not met

---

### 5. Documentation (12 files)

- **START_HERE.md** (this file) - Entry point
- **README.md** - Complete framework overview
- **QUICK_START.md** - 5-minute setup
- **AGENTS_SETUP.md** ⚠️ CRITICAL - Agent setup instructions
- **TEMPLATE_README.md** - Export guide
- **ROADMAP.md** - Layer 3 (CI/CD) plan
- **FRAMEWORK_INDEX.md** - File reference
- **FRAMEWORK_COMPLETE.md** - Complete inventory
- **INVENTORY.md** - File list
- **agents/README.md** - Agent overview
- **agents/AGENTS_INDEX.md** - Complete agent descriptions
- **scripts/README.md** - Script documentation

---

## 🎯 How to Use This Framework

### Step 1: Read Critical Documentation (10 minutes)

1. **This file** (START_HERE.md) - Understanding the problem ✅
2. **AGENTS_SETUP.md** - How to setup agents correctly (CRITICAL)
3. **QUICK_START.md** - 5-minute setup guide
4. **README.md** - Complete framework overview

### Step 2: Copy to Your Project (5 minutes)

```bash
cd C:/Users/Itac/Proyectos/Framework

# CRITICAL: Copy agents to project (not global)
cp -r agents/ /path/to/your/project/.claude/agents/

# Copy enforcement system
cp -r .claude/ /path/to/your/project/

# Copy scripts
cp -r scripts/ /path/to/your/project/

# Copy git hooks
cp -r .husky/ /path/to/your/project/

# Copy documentation
cp AGENTS_SETUP.md /path/to/your/project/
cp TEMPLATE_README.md /path/to/your/project/README_FRAMEWORK.md
```

### Step 3: Install Git Hooks (2 minutes)

```bash
cd /path/to/your/project
bash scripts/install-git-hooks.sh
```

### Step 4: Verify Agents Are Project-Local (1 minute)

```bash
# Should return files (agents are in project)
ls .claude/agents/*.md

# Should NOT use global agents
# If empty, you forgot to copy agents/ to .claude/agents/
```

### Step 5: Test (5 minutes)

```bash
# Test commit hook
echo "# Test" >> README.md
git add README.md
git commit -m "test: Verify hooks"

# Should see:
# ✅ Pre-commit checks passed
# 🔒 FRAMEWORK QUALITY VALIDATION
# ✅ FRAMEWORK VALIDATION PASSED
```

---

## ⚠️ Common Mistakes

### ❌ MISTAKE 1: Using Global Agents

```bash
# WRONG
~/.claude/agents/10-backend-fastapi-dev.md  (global)

# Result: Agent ignores project enforcement
```

**Fix**: Copy agents to project:
```bash
cp -r Framework/agents/ your-project/.claude/agents/
```

---

### ❌ MISTAKE 2: Forgetting to Copy Agents

```bash
# Copied everything EXCEPT agents/
cp -r .claude/ project/
cp -r scripts/ project/
# ... but forgot: cp -r agents/ project/.claude/agents/
```

**Fix**: Copy agents:
```bash
cp -r Framework/agents/ your-project/.claude/agents/
```

---

### ❌ MISTAKE 3: Not Installing Git Hooks

```bash
# Copied files but didn't install hooks
```

**Fix**: Install hooks:
```bash
cd your-project
bash scripts/install-git-hooks.sh
```

---

## ✅ Success Checklist

Framework is working when:

- [ ] Agents are in `.claude/agents/` (not `~/.claude/agents/`)
- [ ] `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` exists
- [ ] `.claude/agent-config.md` exists
- [ ] Git hooks installed (`.git/hooks/pre-commit`, `.git/hooks/pre-push`)
- [ ] Agent output mentions reading AUTOMATIC_HOOK_ENFORCEMENT.md
- [ ] PRE-HOOK executes before work starts
- [ ] POST-HOOK executes after work completes
- [ ] Hook exit code = 0 before marking "complete"
- [ ] No broken code reaches main branch

---

## 🚨 Emergency Troubleshooting

### Problem: Agents not running hooks

**Symptoms**:
- Agent reports "complete" without running POST-HOOK
- No PRE-HOOK output in agent reports
- Agent output doesn't mention AUTOMATIC_HOOK_ENFORCEMENT.md

**Diagnosis**:
```bash
# Check agent location
ls .claude/agents/*.md

# If empty → Agents are GLOBAL (wrong)
# If shows files → Agents are PROJECT (correct)
```

**Fix**:
```bash
# Copy agents to project
cp -r C:/Users/Itac/Proyectos/Framework/agents/ ./.claude/agents/
```

---

### Problem: Git hooks not running

**Symptoms**:
- Can commit code with failing tests
- No hook output when committing

**Diagnosis**:
```bash
# Check hooks installed
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# If missing → Not installed
# If present → Should be executable
```

**Fix**:
```bash
bash scripts/install-git-hooks.sh
```

---

## 📖 Next Steps

After reading this file:

1. ✅ **Read** `AGENTS_SETUP.md` (CRITICAL - explains agent problem/solution)
2. ✅ **Read** `QUICK_START.md` (5-minute setup)
3. ✅ **Copy** framework to your project (including agents/)
4. ✅ **Install** git hooks
5. ✅ **Verify** agents are project-local
6. ✅ **Test** with a commit

---

## 📊 Framework Layers

```
Layer 1: Agent Enforcement
  → Agents in .claude/agents/ (PROJECT, not global)
  → Read AUTOMATIC_HOOK_ENFORCEMENT.md
  → Run PRE-HOOK before work
  → Run POST-HOOK after work
  → 90% effective

Layer 2: Git Hooks
  → pre-commit validates code before commits
  → pre-push validates sprint baseline before pushes
  → Blocks bad commits/pushes
  → 95% effective

Layer 3: CI/CD (Future - see ROADMAP.md)
  → GitHub Actions PR validation
  → Cannot be bypassed
  → 100% effective

Layer 4: Documentation
  → Manual fallback
  → CLAUDE.md, enforcement docs
```

---

**Ready to start?** Read `AGENTS_SETUP.md` next.

**Need quick setup?** Read `QUICK_START.md`.

**Want complete details?** Read `README.md`.

---

**Created**: 2026-03-31
**Version**: 1.0.0
**Purpose**: Entry point for framework documentation
**Critical**: Agents MUST be project-local for enforcement to work
