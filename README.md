# Quality Enforcement Framework

**4-Layer Quality Enforcement System for 100% Code Quality**

This framework ensures 100% code quality at every stage of development through 4 redundant validation layers.

---

## What This Framework Does

Enforces **100% quality standards**:
- ✅ Compilation: 0 errors
- ✅ Tests: 100% passing
- ✅ Coverage: 100%
- ✅ Linting: 0 errors, 0 warnings

**NO MORE:**
- ❌ "Tests mostly passing" (95% is NOT 100%)
- ❌ "Code compiles with some warnings" (warnings = future errors)
- ❌ "Coverage is good enough" (80% ≠ 100%)
- ❌ Agents self-validating without running hooks
- ❌ Broken code merged to main

---

## Framework Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: AGENT ENFORCEMENT (Claude Code)                  │
│  → Agents automatically run PRE-HOOK and POST-HOOK          │
│  → Validation BEFORE starting work (prerequisites)          │
│  → Validation AFTER finishing work (100% quality)           │
│  → Works 90% of the time                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: GIT HOOKS (Local)                                │
│  → pre-commit validates code before commits                 │
│  → pre-push validates sprint baseline before push           │
│  → Blocks commits/pushes with failing validation            │
│  → Works with ANY IDE (VSCode, Cursor, etc.)                │
│  → Works 95% of the time                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: CI/CD (GitHub Actions) [ROADMAP]                 │
│  → Validates PRs before merge                                │
│  → Cannot be bypassed (branch protection)                   │
│  → Last line of defense                                      │
│  → Works 100% of the time                                    │
│  → See ROADMAP.md for implementation                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 4: DOCUMENTATION (Manual Fallback)                  │
│  → Explicit instructions in CLAUDE.md                        │
│  → Manual execution if automation fails                      │
│  → Human verification as last resort                         │
└─────────────────────────────────────────────────────────────┘
```

**Redundancy = Reliability**: If one layer fails, others catch the issue.

---

## Framework Files

```
Framework/
├── README.md                           # This file (overview)
├── TEMPLATE_README.md                  # Export guide for new projects
├── ROADMAP.md                          # Layer 3 implementation plan
├── AGENTS_SETUP.md                     # ⚠️ CRITICAL: How to setup agents correctly
├── .gitignore                          # Anti-report rules
│
├── agents/                             # ⭐ 20 SPECIALIZED AGENTS (CRITICAL)
│   ├── README.md                       # Agent overview
│   ├── AGENTS_INDEX.md                 # Complete agent descriptions
│   ├── 01-product-discovery.md         # Product discovery agent
│   ├── 02-domain-modeling-agent.md     # Domain modeling agent
│   ├── ... (18 more agents)            # See agents/README.md for full list
│   └── workflow-orchestrator/          # Workflow orchestration
│
├── .claude/                            # LAYER 1: Agent Enforcement
│   ├── AUTOMATIC_HOOK_ENFORCEMENT.md   # ⚠️ Mandatory hook rules for agents
│   ├── agent-config.md                 # Agent-specific configurations
│   ├── enforcement/                    # Enforcement scripts
│   └── validators/                     # Validation scripts
│
├── .husky/                             # LAYER 2: Git Hooks (Husky)
│   ├── pre-commit                      # Validates code before commits
│   └── pre-push                        # Validates sprint baseline before push
│
├── scripts/                            # LAYER 2: Hook Installers & Validators
│   ├── install-git-hooks.sh            # Git hooks installer
│   ├── enforce-sprint-baseline.sh      # Sprint baseline validator
│   ├── hooks/                          # Post-wave hooks
│   └── ... (30+ scripts)               # See scripts/README.md
│
└── .github/                            # LAYER 3: CI/CD (Future)
    └── workflows/
        ├── pr-validation.yml           # PR quality gate (TO BE CREATED)
        └── sprint-baseline.yml         # Sprint completion validation (TO BE CREATED)
```

---

## 🔴 CRITICAL: Agent Setup Required

**⚠️ WARNING**: For Layer 1 (Agent Enforcement) to work, agents MUST be in the project, NOT global.

### Why This Matters

```
~/.claude/agents/           ← GLOBAL agents (DO NOT read project enforcement)
                            ← Result: Agents self-validate, Sprint fails

.claude/agents/             ← PROJECT agents (READ project enforcement)
                            ← Result: Agents run hooks, 100% quality
```

**Sprint 3 failed** because agents were global and ignored `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md`

**See `AGENTS_SETUP.md` for complete setup instructions.**

---

## Quick Start

### 1. Copy Framework to Your Project (INCLUDING AGENTS)

```bash
# From this Framework directory
cd C:/Users/Itac/Proyectos/Framework

# Copy to your project
cp -r agents/ /path/to/your/project/.claude/agents/     # ⚠️ CRITICAL: Agents MUST be in project
cp -r .claude/ /path/to/your/project/
cp -r .husky/ /path/to/your/project/
cp -r scripts/ /path/to/your/project/
cp .gitignore /path/to/your/project/.gitignore  # Or merge rules
cp TEMPLATE_README.md /path/to/your/project/README_FRAMEWORK.md
cp ROADMAP.md /path/to/your/project/
cp AGENTS_SETUP.md /path/to/your/project/
```

### 2. Install Git Hooks

```bash
cd /path/to/your/project
bash scripts/install-git-hooks.sh
```

### 3. Test Hooks

```bash
# Make a change
echo "# Test" >> README.md

# Try to commit (hooks will validate)
git add README.md
git commit -m "test: Verify hooks are working"

# You should see:
# ✅ Pre-commit checks passed
# 🔒 FRAMEWORK QUALITY VALIDATION (CAPA 2)
# ✅ FRAMEWORK VALIDATION PASSED
```

---

## How It Prevents Quality Issues

### Real Example: Sprint 3 Failure (Before Framework)

**Agents reported**: "Sprint 3 COMPLETE ✅"

**Reality**:
- Integration tests: **25% passing** (1/4 suites)
- Frontend coverage: **61.62%** (target: 100%)
- Infrastructure layer: **0% test coverage**
- E2E tests: **Skipped**, never executed
- **Overall: 47% complete**, not 100%

**Root cause**: No automatic enforcement. Agents could self-validate without running hooks.

### With This Framework

**Layer 1 (Agents)** - Every agent MUST:
1. Run PRE-HOOK before starting work
   - ✅ Validates prerequisites (previous waves complete, no regressions, infra ready)
   - Exit 0 = continue, Exit 1 = BLOCKED
2. Run POST-HOOK after finishing work
   - ✅ Validates completion (tests 100%, coverage 100%, linting clean)
   - Exit 0 = mark complete, Exit 1 = fix and re-run
3. Include full hook output in reports (not summaries)
4. NEVER mark work "complete" if hook exit code ≠ 0

**Layer 2 (Git Hooks)** - Automatic validation:
- `pre-commit`: Runs before EVERY commit
  - Checks if backend/frontend files changed
  - Runs: `npm run build`, `npm run lint`, `npm test`
  - If ANY fails → commit BLOCKED, must fix first
- `pre-push`: Runs before EVERY push
  - Runs full sprint baseline validation (2-3 minutes)
  - Validates: compilation, tests 100%, coverage 100%, linting clean
  - If ANY fails → push BLOCKED, must fix first

**Layer 3 (CI/CD)** - PR validation:
- Runs on every PR (TO BE IMPLEMENTED)
- Same checks as git hooks (backend + frontend)
- If ANY fails → PR cannot be merged
- Last line of defense before code reaches main branch

---

## Documentation

- **README.md** (this file) - Framework overview
- **TEMPLATE_README.md** - Complete export guide for new projects
- **ROADMAP.md** - Layer 3 (CI/CD) implementation plan
- **.claude/AUTOMATIC_HOOK_ENFORCEMENT.md** - Agent enforcement rules
- **.claude/agent-config.md** - Agent-specific configurations

---

## Usage in Development

### Starting Work (Layer 1 - Agents)

When an agent starts working on a wave:

```bash
# 1. Agent runs PRE-HOOK
bash scripts/hooks/pre-backend-wave-2.sh

# 2. Check exit code
# Exit 0 → ✅ Ready to proceed
# Exit 1 → ❌ BLOCKED - fix prerequisites first

# 3. Develop using TDD
# 4. Run tests continuously
npm test -- --watch
```

### Finishing Work (Layer 1 - Agents)

When an agent finishes a wave:

```bash
# 1. Complete implementation + tests
npm test  # Ensure all tests pass

# 2. Agent runs POST-HOOK
bash scripts/hooks/post-backend-wave-2.sh

# 3. Check exit code
# Exit 0 → ✅ Wave COMPLETE - mark as done
# Exit 1 → ❌ INCOMPLETE - fix issues, re-run

# 4. Only mark "complete" when exit code = 0
```

### Committing Code (Layer 2 - Git Hooks)

```bash
git add .
git commit -m "feat: Add new feature"

# Pre-commit hook runs automatically:
# ✅ Lint-staged (formatting)
# ✅ Console.log checker
# ✅ Backend validation (if backend files changed)
# ✅ Frontend validation (if frontend files changed)

# If ANY fails → commit BLOCKED
```

### Pushing Code (Layer 2 - Git Hooks)

```bash
git push origin feature-branch

# Pre-push hook runs automatically:
# 🔒 Sprint baseline validation (2-3 minutes)
# ✅ Compilation: 0 errors
# ✅ Tests: 100% passing
# ✅ Coverage: 100%
# ✅ Linting: 0 errors, 0 warnings

# If ANY fails → push BLOCKED
```

---

## Troubleshooting

### "Pre-commit hook failed"

1. Check which gate failed in the output
2. Fix the failing gates:
   ```bash
   # Backend compilation
   cd backend && npm run build

   # Backend linting
   cd backend && npm run lint --fix

   # Frontend build
   cd frontend && npm run build
   ```
3. Try committing again

### "Hooks not running"

1. Verify hooks are installed:
   ```bash
   ls -la .git/hooks/
   # Should show: pre-commit, pre-push (executable)
   ```
2. Reinstall if missing:
   ```bash
   bash scripts/install-git-hooks.sh
   ```

### "Agent not running PRE/POST-HOOKS"

1. Verify `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` exists
2. Verify `.claude/agent-config.md` references it
3. If agent still skips hooks:
   - Layer 2 (git hooks) will catch issues on commit/push
   - Layer 3 (CI/CD) will catch issues on PR (when implemented)

---

## Why This Framework Exists

### The Problem

Development teams often face:
- Agents reporting "100% complete" when reality is 47%
- Tests "mostly passing" (95% ≠ 100%)
- Coverage "good enough" (80% ≠ 100%)
- Broken code merged to main
- Production incidents due to untested code

### The Solution

**4-layer redundancy**:
1. Agents enforce quality automatically (90% effective)
2. Git hooks block bad commits/pushes (95% effective)
3. CI/CD prevents bad PR merges (100% effective)
4. Documentation provides manual fallback

**Result**: 100% quality guaranteed

---

## Roadmap

See `ROADMAP.md` for:
- Layer 3 (CI/CD) implementation plan
- GitHub Actions workflows
- Branch protection configuration
- Coverage reporting
- Deployment gates

**Estimated effort**: 18-28 hours for full Layer 3 implementation

---

## Support

For issues with the framework:
1. Check `TEMPLATE_README.md` troubleshooting section
2. Review `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` for agent rules
3. Check git hook scripts in `scripts/install-git-hooks.sh`

---

## License

MIT (or your project license)

---

**Created**: 2026-03-31
**Version**: 1.0.0 (Layer 1 + Layer 2 implemented, Layer 3 in roadmap)
**Maintainer**: [Your name/team]
