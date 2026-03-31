# How to Setup Agents in Your Project

## 🔴 CRITICAL: Why Agents Must Be in the Project

### The Problem with Global Agents

```
~/.claude/agents/
  └── 10-backend-fastapi-dev.md  ← DOES NOT read project's .claude/agent-config.md
                                  ← DOES NOT read AUTOMATIC_HOOK_ENFORCEMENT.md
                                  ← IGNORES project enforcement rules
```

**Result**: Agents self-validate without running hooks → Sprint fails with 47% completion

---

### The Solution: Project-Local Agents

```
your-project/
  └── .claude/
      ├── agent-config.md                  ← Agents READ THIS
      ├── AUTOMATIC_HOOK_ENFORCEMENT.md    ← Agents READ THIS
      └── agents/                           ← Agents ARE HERE
          ├── 01-product-discovery.md
          ├── 10-backend-fastapi-dev.md
          ├── 13-backend-test-agent.md
          └── ... (all 20 agents)
```

**Result**: Agents read project enforcement → Hooks run → 100% quality guaranteed

---

## 📋 How Claude Code Finds Agents

**Priority order**:
1. ✅ `.claude/agents/` in PROJECT (reads project rules)
2. ❌ `~/.claude/agents/` GLOBAL (ignores project rules)

**Recommendation**: ALWAYS use project-local agents for enforcement to work.

---

## 🚀 Setup Instructions

### Step 1: Copy Agents to Your Project

```bash
cd /path/to/your/project

# Copy all agents from Framework
cp -r C:/Users/Itac/Proyectos/Framework/agents/ ./.claude/agents/
```

### Step 2: Verify Agents Are in Project

```bash
ls -la .claude/agents/

# Should show:
# 01-product-discovery.md
# 02-domain-modeling-agent.md
# ...
# 20-linting-validator.md
```

### Step 3: Verify Enforcement Files Exist

```bash
ls -la .claude/

# Should show:
# AUTOMATIC_HOOK_ENFORCEMENT.md  ← CRITICAL
# agent-config.md                ← References enforcement
# agents/                         ← Local agents
```

### Step 4: Test Agent Reads Enforcement

When you invoke an agent, verify it mentions reading enforcement:

```
Agent output should include:
"Reading .claude/AUTOMATIC_HOOK_ENFORCEMENT.md..."
"Running PRE-HOOK validation..."
```

---

## ⚠️ Common Mistakes

### ❌ WRONG: Using Global Agents

```bash
# Agents in global location
~/.claude/agents/10-backend-fastapi-dev.md

# Project has enforcement
proyecto/.claude/AUTOMATIC_HOOK_ENFORCEMENT.md

# Result: Agent IGNORES enforcement ❌
```

### ✅ RIGHT: Using Project-Local Agents

```bash
# Agents in project
proyecto/.claude/agents/10-backend-fastapi-dev.md

# Project has enforcement
proyecto/.claude/AUTOMATIC_HOOK_ENFORCEMENT.md

# Result: Agent READS enforcement ✅
```

---

## 🔧 How to Verify Agents Are Working Correctly

### Test 1: Check Agent Location

```bash
cd your-project

# Should return files (agents are local)
ls .claude/agents/*.md

# Should NOT use global agents
# If using global, copy them to project
```

### Test 2: Invoke Agent and Check Output

```
User: "Implement the authentication service"

Agent should output:
✅ "Reading .claude/AUTOMATIC_HOOK_ENFORCEMENT.md..."
✅ "PRE-HOOK: Validating prerequisites..."
✅ "POST-HOOK: Validating completion..."

If agent does NOT mention enforcement:
❌ Agent is using GLOBAL location (not project)
❌ Copy agents to .claude/agents/ in project
```

### Test 3: Verify POST-HOOK Execution

After agent finishes:

```
Agent report should include:
## POST-HOOK Validation

\```bash
$ bash scripts/hooks/post-backend-wave-2.sh
[FULL OUTPUT HERE]
\```

**Exit Code**: 0
**Status**: ✅ COMPLETE

If POST-HOOK is missing:
❌ Agent did NOT read enforcement
❌ Verify agents are in .claude/agents/ (not ~/.claude/agents/)
```

---

## 🎯 Framework Export Instructions

When exporting this framework to a new project:

### Step 1: Copy Framework Files

```bash
cd /path/to/new/project

# Copy enforcement system
cp -r Framework/.claude/ ./.claude/

# Copy scripts
cp -r Framework/scripts/ ./scripts/

# Copy git hooks
cp -r Framework/.husky/ ./.husky/
```

### Step 2: Verify Agents Location

```bash
# Verify agents are in PROJECT (not global)
ls -la .claude/agents/

# Should show 20 agents
```

### Step 3: Install Git Hooks

```bash
bash scripts/install-git-hooks.sh
```

### Step 4: Test First Agent

```
User: "Help me create the product discovery document"

Expected:
✅ Agent reads .claude/AUTOMATIC_HOOK_ENFORCEMENT.md
✅ Agent mentions PRE-HOOK requirements
✅ Agent executes work following TDD
✅ Agent runs POST-HOOK after completion
```

---

## 📊 Verification Checklist

### Before Starting Development

- [ ] Agents are in `.claude/agents/` (not `~/.claude/agents/`)
- [ ] `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` exists
- [ ] `.claude/agent-config.md` references enforcement
- [ ] Git hooks installed (`.git/hooks/pre-commit`, `.git/hooks/pre-push`)

### During Development

- [ ] Agents mention reading enforcement in output
- [ ] PRE-HOOK executes before work starts
- [ ] POST-HOOK executes after work completes
- [ ] Hook output included in agent reports

### After Completion

- [ ] POST-HOOK exit code = 0
- [ ] All gates passed (compilation, tests, coverage, linting)
- [ ] Work marked "complete" only when hooks pass

---

## 🚨 What Happens If Agents Stay Global?

**Scenario**: Agents in `~/.claude/agents/`, project has `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md`

**Result**:
1. ❌ Agent does NOT read enforcement
2. ❌ Agent does NOT run PRE-HOOK
3. ❌ Agent does NOT run POST-HOOK
4. ❌ Agent self-validates (reports "100% complete")
5. ❌ Reality: 47% complete (Sprint 3 example)
6. ❌ Broken code reaches main branch

**Fix**: Move agents to `.claude/agents/` in project

---

## ✅ Success Criteria

Framework is working correctly when:

1. ✅ Agents are in `.claude/agents/` (not global)
2. ✅ Agent output mentions reading AUTOMATIC_HOOK_ENFORCEMENT.md
3. ✅ PRE-HOOK executes before work (validates prerequisites)
4. ✅ POST-HOOK executes after work (validates 100% quality)
5. ✅ Hook exit code = 0 before marking "complete"
6. ✅ No broken code reaches main branch

---

## 📖 Related Documentation

- **AUTOMATIC_HOOK_ENFORCEMENT.md** - Mandatory hook rules
- **agent-config.md** - Agent-specific configurations
- **Framework/agents/README.md** - Agent descriptions
- **Framework/agents/AGENTS_INDEX.md** - Complete agent index

---

**Created**: 2026-03-31
**Version**: 1.0.0
**Critical**: Agents MUST be project-local, not global
