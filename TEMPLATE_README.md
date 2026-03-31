# Quality Enforcement Framework - Template

This project includes a **4-layer quality enforcement framework** that ensures 100% code quality at every stage of development. This README explains how to export and use this framework in other projects.

---

## What This Framework Does

The framework enforces **100% quality standards**:
- ✅ Compilation: 0 errors
- ✅ Tests: 100% passing
- ✅ Coverage: 100%
- ✅ Linting: 0 errors, 0 warnings

**It works through 4 redundant layers:**

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: AGENT ENFORCEMENT (Claude Code)                  │
│  → Agents automatically run PRE-HOOK and POST-HOOK          │
│  → Works 90% of the time with Claude Code                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: GIT HOOKS (Local)                                │
│  → pre-commit validates code before commits                 │
│  → pre-push validates sprint baseline before push           │
│  → Works with ANY IDE (VSCode, Cursor, etc.)                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: CI/CD (GitHub Actions) [ROADMAP]                 │
│  → Validates PRs before merge                                │
│  → Last line of defense                                      │
│  → See ROADMAP.md for implementation plan                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LAYER 4: DOCUMENTATION (Manual Fallback)                  │
│  → Explicit instructions in CLAUDE.md                        │
│  → If all automation fails, developers follow manual steps   │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Included in This Framework

### Layer 1: Agent Enforcement
```
.claude/
├── AUTOMATIC_HOOK_ENFORCEMENT.md   # Mandatory PRE/POST-HOOK rules for all agents
├── agent-config.md                  # Agent-specific configurations
└── settings.local.json              # Claude Code settings
```

### Layer 2: Git Hooks
```
scripts/
├── install-git-hooks.sh             # Installer for git hooks
├── enforce-sprint-baseline.sh       # Sprint baseline validator (if exists)
└── hooks/                           # Wave-specific hooks (if exist)
    ├── pre-backend-wave-1.sh
    ├── post-backend-wave-1.sh
    └── ...

.git/hooks/                          # Actual git hooks (created by installer)
├── pre-commit                       # Validates code before commits
└── pre-push                         # Validates sprint baseline before push
```

### Layer 3: CI/CD (Future)
```
.github/
└── workflows/
    ├── pr-validation.yml            # PR quality gate (TO BE CREATED)
    └── sprint-baseline.yml          # Sprint completion validation (TO BE CREATED)
```

### Layer 4: Documentation
```
CLAUDE.md                            # Project-specific development guide
docs/
├── INICIALIZACION_FRAMEWORK.md     # Framework initialization protocol (if exists)
└── PLAN_DESARROLLO_SPRINT.md       # Sprint development plan (if exists)
```

---

## How to Export This Framework to a New Project

### Step 1: Copy Framework Files

Copy these directories/files to your new project:

```bash
# Create new project directory
mkdir my-new-project
cd my-new-project

# Copy Layer 1 (Agent Enforcement)
cp -r /path/to/template/.claude/ ./.claude/

# Copy Layer 2 (Git Hooks)
cp -r /path/to/template/scripts/ ./scripts/

# Copy Layer 4 (Documentation)
cp /path/to/template/CLAUDE.md ./CLAUDE.md
cp /path/to/template/TEMPLATE_README.md ./README_FRAMEWORK.md
cp /path/to/template/ROADMAP.md ./ROADMAP.md  # If exists

# Optional: Copy project docs if they exist
mkdir -p docs
cp /path/to/template/docs/INICIALIZACION_FRAMEWORK.md ./docs/  # If exists
cp /path/to/template/docs/PLAN_DESARROLLO_SPRINT.md ./docs/    # If exists
```

### Step 2: Update .gitignore

Add these rules to your `.gitignore`:

```gitignore
# Block all report/summary/completion spam (Layer 1 enforcement)
*_report.md
*_REPORT.md
*report*.md
*Report*.md
*completion*.md
*COMPLETION*.md
*summary*.md
*SUMMARY*.md
*INFORME*.md
*FASE*.md
*FIX_REPORT*.md
*AUDIT*.md
.project-orchestration/*.md
smoke-test-report.md

# Allow design documents (01-09)
!01_*.md
!02_*.md
!03_*.md
!04_*.md
!05_*.md
!06_*.md
!07_*.md
!08_*.md
!09_*.md
```

### Step 3: Install Git Hooks

```bash
# Run the installer (creates .git/hooks/pre-commit and .git/hooks/pre-push)
bash scripts/install-git-hooks.sh
```

**Output should show:**
```
✅ GIT HOOKS INSTALLED SUCCESSFULLY

Installed hooks:
  • pre-commit → Validates code before commits
  • pre-push → Validates sprint baseline before push
```

### Step 4: Customize for Your Project

Edit these files to match your project:

1. **`CLAUDE.md`** - Update with your project-specific:
   - Technology stack
   - Commands (npm run dev, test, build)
   - Port configuration
   - Module structure
   - Architecture details

2. **`.claude/agent-config.md`** (if needed) - Update agent-specific rules

3. **`scripts/install-git-hooks.sh`** - Adjust validation commands if needed:
   - Backend commands: `npm run build`, `npm run lint`, `npm test`
   - Frontend commands: `npm run type-check`, `npm run build`, `npm run lint`

### Step 5: Initialize Git Repository

```bash
git init
git add .
git commit -m "chore: initialize project with quality enforcement framework"
```

**Note**: First commit will trigger `pre-commit` hook, which will validate your code.

---

## How the Framework Prevents Quality Issues

### Before This Framework (Sprint 3 Example)

**Agents reported "complete"**, but reality was:
- Integration tests: 25% passing (1/4 suites)
- Frontend coverage: 61.62% (target: 100%)
- Infrastructure layer: 0% test coverage
- E2E tests: Skipped, never executed
- **Overall: 47% complete, not 100%**

**Root cause**: No automatic enforcement. Agents could self-validate without running hooks.

### With This Framework

**Layer 1 (Agents)** - Automatic enforcement:
```markdown
Every agent MUST:
1. Run PRE-HOOK before starting work
   → Validates prerequisites (previous waves complete, no regressions, infra ready)
   → Exit 0 = continue, Exit 1 = BLOCKED

2. Run POST-HOOK after finishing work
   → Validates completion (tests 100%, coverage 100%, linting clean)
   → Exit 0 = mark complete, Exit 1 = fix and re-run

3. Include full hook output in reports (not summaries)

4. NEVER mark work "complete" if hook exit code ≠ 0
```

**Layer 2 (Git Hooks)** - Local validation:
```bash
# pre-commit (runs before EVERY commit)
→ Checks if backend/frontend files changed
→ Runs: npm run build, npm run lint, npm test
→ If ANY fails → commit BLOCKED, must fix first

# pre-push (runs before EVERY push)
→ Runs full sprint baseline validation (2-3 minutes)
→ Validates: compilation, tests 100%, coverage 100%, linting clean
→ If ANY fails → push BLOCKED, must fix first
```

**Layer 3 (CI/CD)** - PR validation (future):
```yaml
# .github/workflows/pr-validation.yml (TO BE CREATED)
→ Runs on every PR
→ Same checks as git hooks (backend + frontend)
→ If ANY fails → PR cannot be merged
→ Last line of defense before code reaches main branch
```

---

## How to Use This Framework in Development

### Starting a New Wave

```bash
# 1. Agent runs PRE-HOOK
bash scripts/hooks/pre-backend-wave-2.sh  # Example: Wave 2

# 2. Check exit code
# Exit 0 → ✅ Ready to proceed
# Exit 1 → ❌ BLOCKED - fix prerequisites first

# 3. Develop features using TDD
# RED → GREEN → REFACTOR

# 4. Run tests continuously
npm test -- --watch
```

### Finishing a Wave

```bash
# 1. Complete implementation + tests
npm test  # Ensure all tests pass locally

# 2. Agent runs POST-HOOK
bash scripts/hooks/post-backend-wave-2.sh  # Example: Wave 2

# 3. Check exit code
# Exit 0 → ✅ Wave COMPLETE - mark as done
# Exit 1 → ❌ INCOMPLETE - fix issues, re-run

# 4. Only mark work "complete" when exit code = 0
```

### Committing Code

```bash
# Add files
git add .

# Commit (pre-commit hook runs automatically)
git commit -m "feat(module): add feature X"

# If pre-commit fails:
# → Git blocks the commit
# → Fix the reported issues (compilation, linting, tests)
# → Try again: git commit --amend
```

### Pushing Code

```bash
# Push (pre-push hook runs automatically)
git push origin feature-branch

# If pre-push fails:
# → Git blocks the push
# → Sprint baseline not met (tests failing, coverage low, etc.)
# → Fix ALL issues until baseline is met
# → Try again: git push
```

### Bypassing Hooks (NOT RECOMMENDED)

```bash
# Skip pre-commit (dangerous)
git commit --no-verify

# Skip pre-push (dangerous)
git push --no-verify
```

**WARNING**: Bypassing hooks defeats the purpose of the framework. Only use in emergencies.

---

## Troubleshooting

### "pre-commit hook failed"

1. Check which gate failed:
   ```
   ❌ Backend Compilation
   ❌ Backend Linting
   ✅ Backend Tests
   ❌ Frontend Build
   ```

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

### "pre-push hook failed"

1. Check the baseline report:
   ```bash
   cat .project-orchestration/sprint-*-baseline-report-*.md
   ```

2. Identify which gates failed (compilation, tests, coverage, linting)

3. Fix ALL failing gates until 100%

4. Try pushing again

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

3. Check hook permissions:
   ```bash
   chmod +x .git/hooks/pre-commit
   chmod +x .git/hooks/pre-push
   ```

### "Agent not running PRE/POST-HOOKS"

1. Verify `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` exists

2. Verify `.claude/agent-config.md` references it

3. If agent still skips hooks:
   - Layer 2 (git hooks) will catch issues on commit/push
   - Layer 3 (CI/CD) will catch issues on PR (when implemented)

---

## Framework Roadmap

See `ROADMAP.md` for future enhancements:
- **Layer 3 (CI/CD)**: GitHub Actions for PR validation
- **Layer 3 (CI/CD)**: Sprint baseline validation on push
- **Automated reporting**: Test results, coverage reports
- **Dashboard**: Visual sprint progress tracking

---

## Support

For issues with the framework:
1. Check this README's troubleshooting section
2. Review `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` for agent rules
3. Review `CLAUDE.md` for project-specific guidance
4. Check git hook scripts in `scripts/install-git-hooks.sh`

---

**Created**: 2026-03-31
**Version**: 1.0.0 (Layer 1 + Layer 2 implemented, Layer 3 in roadmap)
**License**: MIT (or your project license)
**Maintainer**: [Your name/team]
