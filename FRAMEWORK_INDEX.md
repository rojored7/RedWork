# Framework File Index

This document provides a quick reference to all files in the Quality Enforcement Framework.

---

## Directory Structure

```
Framework/
├── README.md                           # Framework overview and quick start
├── TEMPLATE_README.md                  # Complete export guide
├── ROADMAP.md                          # Layer 3 (CI/CD) implementation plan
├── FRAMEWORK_INDEX.md                  # This file (file reference)
├── CLAUDE.md                           # Example project-specific guide
├── .gitignore                          # Anti-report rules
│
├── .claude/                            # LAYER 1: Agent Enforcement
│   ├── AUTOMATIC_HOOK_ENFORCEMENT.md   # Mandatory hook rules (10 non-negotiable rules)
│   ├── agent-config.md                 # Agent-specific configurations
│   └── settings.local.json             # Example Claude Code settings
│
├── .husky/                             # LAYER 2: Git Hooks (Husky)
│   ├── pre-commit                      # Validates code before commits
│   └── pre-push                        # Validates sprint baseline before push
│
├── scripts/                            # LAYER 2: Hook Installers
│   └── install-git-hooks.sh            # Git hooks installer for new developers
│
└── .github/                            # LAYER 3: CI/CD (Future - empty for now)
    └── workflows/
        ├── pr-validation.yml           # TO BE CREATED (see ROADMAP.md Phase 1)
        └── sprint-baseline.yml         # TO BE CREATED (see ROADMAP.md Phase 5)
```

---

## File Descriptions

### Root Files

| File | Purpose | When to Use |
|------|---------|-------------|
| **README.md** | Framework overview, architecture, quick start | First file to read when exploring the framework |
| **TEMPLATE_README.md** | Complete export guide for using framework in new projects | When copying framework to a new project |
| **ROADMAP.md** | Layer 3 (CI/CD) implementation plan with 6 phases | When ready to implement GitHub Actions |
| **FRAMEWORK_INDEX.md** | This file - quick reference to all framework files | When you need to find a specific file or understand structure |
| **CLAUDE.md** | Example project-specific development guide | Reference when creating CLAUDE.md for your project |
| **.gitignore** | Rules to block report spam | Copy/merge into project .gitignore |

---

### Layer 1: Agent Enforcement (`.claude/`)

| File | Purpose | Who Uses It |
|------|---------|-------------|
| **AUTOMATIC_HOOK_ENFORCEMENT.md** | Defines mandatory PRE-HOOK and POST-HOOK rules for all agents | ALL agents read this BEFORE starting work |
| **agent-config.md** | Agent-specific configurations and references | Agents reference this for specific instructions |
| **settings.local.json** | Example Claude Code settings | Copy to your project and customize |

**Key Concepts**:
- **PRE-HOOK**: Validates prerequisites before starting work (exit 0 = ready, exit 1 = blocked)
- **POST-HOOK**: Validates completion after finishing work (exit 0 = complete, exit 1 = incomplete)
- **10 Non-Negotiable Rules**: Cannot skip hooks, cannot self-validate, cannot mark complete if hooks fail

---

### Layer 2: Git Hooks (`.husky/` and `scripts/`)

| File | Purpose | When It Runs |
|------|---------|--------------|
| **.husky/pre-commit** | Validates code before allowing commits | Runs automatically before EVERY `git commit` |
| **.husky/pre-push** | Validates sprint baseline before allowing pushes | Runs automatically before EVERY `git push` |
| **scripts/install-git-hooks.sh** | Installs git hooks into `.git/hooks/` | Run once after cloning repository |

**What pre-commit validates**:
- Lint-staged (code formatting)
- Console.log detection in staged files
- **Backend validation** (if backend files changed):
  - Compilation: `npm run build` (0 errors)
  - Linting: `npm run lint` (0 errors, 0 warnings)
  - Tests: `npm test` (100% passing)
- **Frontend validation** (if frontend files changed):
  - Type checking: `npm run type-check` (0 errors)
  - Build: `npm run build` (0 errors)
  - Linting: `npm run lint` (0 errors, 0 warnings)
  - Tests: `npm test` (100% passing)

**What pre-push validates**:
- Runs `scripts/enforce-sprint-baseline.sh` (if exists)
- Validates sprint is 100% complete before allowing push to remote

**Bypass** (not recommended):
```bash
git commit --no-verify  # Skip pre-commit
git push --no-verify    # Skip pre-push
```

---

### Layer 3: CI/CD (`.github/workflows/` - Future)

| File | Purpose | Status |
|------|---------|--------|
| **pr-validation.yml** | Validates PR before merge (compilation, linting, tests) | 📋 TO BE CREATED (see ROADMAP.md Phase 1) |
| **sprint-baseline.yml** | Validates sprint completion before merging to main | 📋 TO BE CREATED (see ROADMAP.md Phase 5) |

See `ROADMAP.md` for complete implementation plan (18-28 hours estimated).

---

## How Files Work Together

### Scenario 1: Agent Starts Work on Wave 2

```
1. Agent reads: .claude/AUTOMATIC_HOOK_ENFORCEMENT.md
   → "I must run PRE-HOOK before starting"

2. Agent executes: bash scripts/hooks/pre-backend-wave-2.sh
   → Exit 0: ✅ Ready to proceed
   → Exit 1: ❌ BLOCKED (prerequisites not met)

3. Agent develops features using TDD

4. Agent executes: bash scripts/hooks/post-backend-wave-2.sh
   → Exit 0: ✅ Wave 2 COMPLETE
   → Exit 1: ❌ INCOMPLETE (fix issues, re-run)

5. Agent reports: "Wave 2 COMPLETE" only if POST-HOOK exit 0
```

### Scenario 2: Developer Commits Code

```
1. Developer: git add . && git commit -m "feat: Add feature"

2. Husky runs: .husky/pre-commit
   → Validates lint-staged
   → Checks console.log in staged files
   → If backend changed: runs build, lint, test
   → If frontend changed: runs type-check, build, lint, test

3. Pre-commit result:
   → Exit 0: ✅ Commit succeeds
   → Exit 1: ❌ Commit BLOCKED (must fix issues)

4. Developer: git push origin feature-branch

5. Husky runs: .husky/pre-push
   → Runs full sprint baseline validation
   → Validates 100% quality

6. Pre-push result:
   → Exit 0: ✅ Push succeeds
   → Exit 1: ❌ Push BLOCKED (must fix issues)
```

### Scenario 3: Export Framework to New Project

```
1. Developer reads: README.md (overview)
2. Developer reads: TEMPLATE_README.md (export guide)
3. Developer copies files:
   - .claude/ (Layer 1)
   - .husky/ (Layer 2)
   - scripts/ (Layer 2)
   - .gitignore (anti-report rules)
4. Developer runs: bash scripts/install-git-hooks.sh
5. Developer tests: git commit (hooks should run)
6. Developer customizes: CLAUDE.md for project
7. Later: Implement Layer 3 using ROADMAP.md
```

---

## File Dependencies

### AUTOMATIC_HOOK_ENFORCEMENT.md depends on:
- Hook scripts in `scripts/hooks/` (if they exist in your project)
- Agent must have access to bash/shell

### pre-commit depends on:
- `package.json` with `lint-staged` configured
- Backend: `npm run build`, `npm run lint`, `npm test`
- Frontend: `npm run type-check`, `npm run build`, `npm run lint`, `npm test`

### pre-push depends on:
- `scripts/enforce-sprint-baseline.sh` (if exists)
- Sprint detection from git branch name

### install-git-hooks.sh depends on:
- `.git/` directory (must be a git repository)
- Bash shell

---

## Customization Guide

### For Your Project

1. **Keep as-is**:
   - `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` (universal rules)
   - `.husky/pre-commit` (universal validation)
   - `scripts/install-git-hooks.sh` (universal installer)
   - `.gitignore` (anti-report rules)

2. **Customize**:
   - `.claude/agent-config.md` (add project-specific agent rules)
   - `.husky/pre-push` (adjust sprint baseline validation)
   - `CLAUDE.md` (create project-specific guide)
   - `.claude/settings.local.json` (project settings)

3. **Add later**:
   - `scripts/hooks/pre-*.sh` (wave-specific pre-hooks)
   - `scripts/hooks/post-*.sh` (wave-specific post-hooks)
   - `.github/workflows/*.yml` (Layer 3 CI/CD)

---

## Quick Command Reference

```bash
# Install framework in new project
bash scripts/install-git-hooks.sh

# Verify hooks installed
ls -la .git/hooks/

# Test hooks
git add . && git commit -m "test: Verify hooks"

# Bypass hooks (NOT RECOMMENDED)
git commit --no-verify
git push --no-verify

# Read framework docs
cat README.md                           # Overview
cat TEMPLATE_README.md                  # Export guide
cat ROADMAP.md                          # Layer 3 plan
cat .claude/AUTOMATIC_HOOK_ENFORCEMENT.md  # Agent rules
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-31 | Initial framework with Layer 1 + Layer 2 implemented |

---

## Next Steps

1. **If this is your first time**:
   - Read `README.md` for overview
   - Read `TEMPLATE_README.md` for export guide
   - Copy framework to your project
   - Run `bash scripts/install-git-hooks.sh`

2. **If implementing Layer 3**:
   - Read `ROADMAP.md` for CI/CD plan
   - Follow Phase 1 (Basic PR Validation)
   - Configure branch protection on GitHub

3. **If customizing for your project**:
   - Update `.claude/agent-config.md` with project-specific rules
   - Create custom `CLAUDE.md` (use provided example)
   - Add wave-specific hooks in `scripts/hooks/`

---

**Need help?** Check troubleshooting section in `TEMPLATE_README.md`
