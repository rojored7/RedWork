# Quality Enforcement Framework - Quick Start

**Get up and running in 5 minutes**

---

## What This Framework Does

Guarantees **100% code quality** through 4 automatic validation layers:

```
Layer 1 (Agents)  →  Layer 2 (Git Hooks)  →  Layer 3 (CI/CD)  →  Layer 4 (Docs)
    90%                    95%                    100%              Manual
```

**Result**: NO broken code reaches production.

---

## Installation (2 minutes)

### Step 1: Copy Framework to Your Project

```bash
# Navigate to your project
cd /path/to/your/project

# Copy framework files
cp -r C:/Users/Itac/Proyectos/Framework/.claude/ .
cp -r C:/Users/Itac/Proyectos/Framework/.husky/ .
cp -r C:/Users/Itac/Proyectos/Framework/scripts/ .
cp C:/Users/Itac/Proyectos/Framework/.gitignore .gitignore  # Or merge rules
```

### Step 2: Install Git Hooks

```bash
bash scripts/install-git-hooks.sh
```

**Expected output**:
```
✅ GIT HOOKS INSTALLED SUCCESSFULLY

Installed hooks:
  • pre-commit → Validates code before commits
  • pre-push → Validates sprint baseline before push
```

### Step 3: Test Hooks

```bash
echo "# Test" >> README.md
git add README.md
git commit -m "test: Verify hooks working"
```

**Expected output**:
```
✅ Pre-commit checks passed
🔒 FRAMEWORK QUALITY VALIDATION (CAPA 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ FRAMEWORK VALIDATION PASSED
```

**If you see this → Framework is working! ✅**

---

## File Overview

### Must-Read Files

| File | Purpose | Time to Read |
|------|---------|--------------|
| **README.md** | Framework overview and architecture | 5 min |
| **TEMPLATE_README.md** | Complete export and usage guide | 10 min |
| **.claude/AUTOMATIC_HOOK_ENFORCEMENT.md** | Agent hook rules | 5 min |

### Reference Files

| File | Purpose | When to Read |
|------|---------|--------------|
| **ROADMAP.md** | Layer 3 (CI/CD) implementation plan | When ready for GitHub Actions |
| **FRAMEWORK_INDEX.md** | File reference and descriptions | When looking for specific info |
| **QUICK_START.md** | This file - fast setup | First time setup |

---

## How It Works

### Layer 1: Agent Enforcement

**When**: Agent works on a feature/wave

**What happens**:
1. Agent reads `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md`
2. Agent runs PRE-HOOK before starting (validates prerequisites)
3. Agent develops using TDD
4. Agent runs POST-HOOK after finishing (validates 100% quality)
5. Agent marks "complete" ONLY if POST-HOOK exit code = 0

**Blocks**: Agent self-validation without running hooks

---

### Layer 2: Git Hooks

**When**: You commit or push code

**What happens**:

**pre-commit** (before every commit):
- ✅ Formats code (lint-staged)
- ✅ Checks console.log in staged files
- ✅ **If backend changed**: Compiles, lints, tests backend
- ✅ **If frontend changed**: Type-checks, builds, lints, tests frontend
- ❌ Blocks commit if ANY validation fails

**pre-push** (before every push):
- ✅ Runs full sprint baseline validation
- ✅ Validates: compilation, tests 100%, coverage 100%, linting clean
- ❌ Blocks push if baseline not met

**Blocks**: Committing/pushing broken code

---

### Layer 3: CI/CD (Future - see ROADMAP.md)

**When**: You open a PR

**What happens**:
- ✅ GitHub Actions runs all validations
- ✅ PR blocked until ALL checks pass
- ✅ Branch protection prevents merge of broken code

**Blocks**: Merging broken PRs (100% effective, cannot bypass)

---

## Daily Usage

### Starting Work

```bash
# Agent automatically runs PRE-HOOK
# You don't need to do anything
```

### During Development

```bash
# Run tests continuously
npm test -- --watch

# Check compilation
npm run build

# Fix linting
npm run lint --fix
```

### Committing

```bash
git add .
git commit -m "feat: Add new feature"

# Pre-commit hook validates automatically
# Commit succeeds if validation passes
# Commit blocked if validation fails
```

### Pushing

```bash
git push origin feature-branch

# Pre-push hook validates sprint baseline
# Push succeeds if baseline met
# Push blocked if baseline not met
```

---

## Common Issues

### "Pre-commit hook failed"

**Problem**: Code doesn't pass validation

**Solution**:
```bash
# Check which gate failed (shown in output)
# Fix the issue:
cd backend && npm run build    # If compilation failed
cd backend && npm run lint --fix  # If linting failed
cd backend && npm test         # If tests failed
```

### "Hooks not running"

**Problem**: Git hooks not installed

**Solution**:
```bash
bash scripts/install-git-hooks.sh
```

### "Agent skipped hooks"

**Problem**: Agent didn't run PRE/POST-HOOK

**Solution**:
- Layer 2 (git hooks) will catch issues on commit/push
- Verify `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` exists
- Update `.claude/agent-config.md` to reference enforcement doc

---

## Bypassing Hooks (NOT RECOMMENDED)

**Only use in emergencies**:

```bash
# Skip pre-commit
git commit --no-verify

# Skip pre-push
git push --no-verify
```

**Warning**: Bypassing defeats the purpose of the framework. Only use when absolutely necessary.

---

## Next Steps

### Immediate (Now)
1. ✅ Install framework (you just did this)
2. ✅ Test hooks work
3. 📖 Read `README.md` (5 minutes)
4. 📖 Read `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` (5 minutes)

### Short Term (This Week)
1. Customize `.claude/agent-config.md` for your project
2. Create custom `CLAUDE.md` (use provided example)
3. Add wave-specific hooks in `scripts/hooks/` (if needed)

### Long Term (Next Sprint)
1. Read `ROADMAP.md` for Layer 3 (CI/CD) plan
2. Implement GitHub Actions workflows
3. Configure branch protection rules
4. Train team on framework usage

---

## Support

**Need help?**
1. Check troubleshooting in `TEMPLATE_README.md`
2. Review file reference in `FRAMEWORK_INDEX.md`
3. Read agent rules in `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md`

---

## Success Metrics

**Framework is working when you see**:
- ✅ Pre-commit hook runs on every commit
- ✅ Pre-push hook runs on every push
- ✅ Agents report PRE-HOOK and POST-HOOK execution
- ✅ No broken code reaches main branch
- ✅ Tests: 100% passing always
- ✅ Coverage: 100% always
- ✅ Compilation: 0 errors always

**Framework is NOT working when**:
- ❌ Commits succeed with failing tests
- ❌ Pushes succeed with < 100% coverage
- ❌ Agents mark "complete" without running POST-HOOK
- ❌ Broken code merged to main

---

**Questions?** Read `README.md` for full documentation.

**Ready to implement CI/CD?** Read `ROADMAP.md` for Layer 3 plan.

---

**Created**: 2026-03-31
**Version**: 1.0.0
**Setup Time**: 5 minutes
