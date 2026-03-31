# 🚨 CAPA 1: AUTOMATIC HOOK ENFORCEMENT

**This file defines MANDATORY rules that ALL agents MUST follow**

---

## ⛔ THIS IS NOT OPTIONAL - IT IS AUTOMATIC ⛔

```
┌──────────────────────────────────────────────────────────┐
│  IF YOU ARE AN AGENT READING THIS:                      │
│                                                          │
│  PRE-HOOK and POST-HOOK execution is NOT optional.      │
│  It is like compiling code before running it.           │
│  You CANNOT skip it. You MUST execute it.               │
│                                                          │
│  EVERY time you touch code → HOOKS RUN                  │
│  EVERY time you run tests → HOOKS RUN                   │
│  EVERY time you mark "complete" → HOOKS RUN             │
└──────────────────────────────────────────────────────────┘
```

---

## 🔒 UNIVERSAL PRE-HOOK REQUIREMENT

### When: BEFORE starting ANY development work

**Steps**:

1. **Identify which wave you're working on** (Wave 1, 2, 3, 4, or 5)

2. **Execute PRE-HOOK for that wave**:
   ```bash
   # Backend Wave 1 (Domain):
   bash scripts/hooks/pre-backend-wave-1.sh

   # Backend Wave 2 (Application):
   bash scripts/hooks/pre-backend-wave-2.sh

   # Backend Wave 3 (API):
   bash scripts/hooks/pre-backend-wave-3.sh

   # Frontend Wave 4:
   bash scripts/hooks/pre-frontend-wave-4.sh

   # Integration Tests:
   bash scripts/hooks/pre-backend-integration-test.sh

   # E2E Tests:
   bash scripts/hooks/pre-e2e-test.sh
   ```

3. **Check exit code**:
   - `Exit 0` → ✅ Continue with development
   - `Exit 1` → ❌ **BLOCKED** - Fix prerequisites first

4. **If PRE-HOOK fails (exit 1)**:
   ```
   ❌ DO NOT continue with development
   📝 Report which prerequisite failed
   🔧 Fix the issue (dependencies, infrastructure, regressions)
   🔄 Re-run PRE-HOOK
   ✅ Only proceed when exit code = 0
   ```

### What PRE-HOOK validates:

- ✅ Previous waves complete (flags exist)
- ✅ No regressions (existing tests still pass)
- ✅ Infrastructure ready (PostgreSQL, Redis UP)
- ✅ Compilation works (0 errors)
- ✅ Dependencies installed
- ✅ Environment variables set

### Example PRE-HOOK execution:

```bash
# Before starting Wave 2 development:
$ bash scripts/hooks/pre-backend-wave-2.sh

🔍 PRE-HOOK VALIDATION for Wave 2 (Application Layer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ GATE 1: Wave 1 complete (flag exists)
✅ GATE 2: Backend compiles (0 errors)
✅ GATE 3: Existing tests pass (100%)
✅ GATE 4: Infrastructure UP (PostgreSQL, Redis)

✅✅✅ PRE-HOOK PASSED - READY FOR WAVE 2 ✅✅✅
Exit code: 0
```

**Agent Response**: "PRE-HOOK passed, proceeding with Wave 2 development..."

---

## 🔒 UNIVERSAL POST-HOOK REQUIREMENT

### When: AFTER completing ALL work for a wave

**Steps**:

1. **Complete your implementation**
   - Write code
   - Write tests
   - Run tests locally

2. **Execute POST-HOOK for that wave**:
   ```bash
   # Backend Wave 1 (Domain):
   bash scripts/hooks/post-backend-wave-1.sh

   # Backend Wave 2 (Application):
   bash scripts/hooks/post-backend-wave-2.sh

   # Backend Wave 3 (API):
   bash scripts/hooks/post-backend-wave-3.sh

   # Frontend Wave 4:
   bash scripts/hooks/post-frontend-wave-4.sh

   # Integration Tests:
   bash scripts/hooks/post-backend-integration-test.sh

   # E2E Tests:
   bash scripts/hooks/post-e2e-test.sh
   ```

3. **Check exit code**:
   - `Exit 0` → ✅ Wave COMPLETE - mark as done
   - `Exit 1` → ❌ **INCOMPLETE** - fix issues, re-run

4. **If POST-HOOK fails (exit 1)**:
   ```
   ❌ DO NOT mark wave as "complete"
   📝 Identify which gate failed
   🔧 Fix the failing gate
   🔄 Re-run POST-HOOK
   ✅ Only mark complete when exit code = 0
   ```

### What POST-HOOK validates:

- ✅ Compilation succeeds (0 errors)
- ✅ All tests pass (100%)
- ✅ Coverage = 100%
- ✅ Linting clean (0 errors, 0 warnings)
- ✅ No regressions in previous waves
- ✅ Flags created as evidence

### Example POST-HOOK execution:

```bash
# After completing Wave 2 development:
$ bash scripts/hooks/post-backend-wave-2.sh

🔍 POST-HOOK VALIDATION for Wave 2 (Application Layer)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ GATE 1: Backend compiles (0 errors)
✅ GATE 2: Unit tests pass (100% - 145/145)
✅ GATE 3: Coverage = 100%
✅ GATE 4: Linting clean (0 errors, 0 warnings)
✅ GATE 5: No regressions in Wave 1

✅ FLAG CREATED: scripts/hooks/gate-flags/wave-2-backend-complete.flag

✅✅✅ POST-HOOK PASSED - WAVE 2 COMPLETE ✅✅✅
Exit code: 0
```

**Agent Response**: "POST-HOOK passed (exit 0), Wave 2 is COMPLETE."

---

## 📋 MANDATORY REPORT FORMAT

**Every agent report MUST include**:

```markdown
## PRE-HOOK Validation

\```bash
$ bash scripts/hooks/pre-backend-wave-X.sh
[FULL OUTPUT HERE - NOT SUMMARY]
\```

**Exit Code**: 0 or 1
**Status**: ✅ PASSED or ❌ FAILED

---

## [Your Work Here]

[Agent implements features, writes tests, etc.]

---

## POST-HOOK Validation

\```bash
$ bash scripts/hooks/post-backend-wave-X.sh
[FULL OUTPUT HERE - NOT SUMMARY]
\```

**Exit Code**: 0 or 1
**Status**: ✅ COMPLETE or ❌ INCOMPLETE

### Flags Created:
- ✅ `scripts/hooks/gate-flags/wave-X-complete.flag`
```

---

## ❌ FORBIDDEN PATTERNS

### ❌ DO NOT skip PRE-HOOK:
```
Agent: "Starting Wave 2 development..."
[CODE IMPLEMENTATION WITHOUT PRE-HOOK]
```
**WRONG**: Must run PRE-HOOK first

### ❌ DO NOT skip POST-HOOK:
```
Agent: "Wave 2 complete! All tests passing."
[NO POST-HOOK EXECUTION]
```
**WRONG**: Must run POST-HOOK and show output

### ❌ DO NOT summarize hooks:
```
## POST-HOOK Validation
Hook passed successfully.
```
**WRONG**: Must show FULL hook output

### ❌ DO NOT mark complete if hook fails:
```
## POST-HOOK Validation
Exit code: 1

## Status
✅ Wave 2 COMPLETE
```
**WRONG**: Cannot be complete if exit code ≠ 0

---

## ✅ CORRECT PATTERN

```markdown
## PRE-HOOK Validation

\```bash
$ bash scripts/hooks/pre-backend-wave-2.sh
🔍 PRE-HOOK VALIDATION for Wave 2
✅ GATE 1: Wave 1 complete
✅ GATE 2: Backend compiles
✅ GATE 3: Tests pass
✅✅✅ PRE-HOOK PASSED ✅✅✅
\```

**Exit Code**: 0
**Status**: ✅ PASSED - Ready to proceed

---

## Wave 2 Implementation

[Agent writes services, DTOs, use cases...]
[Agent writes tests following TDD...]
[Agent runs: npm test]

```bash
$ npm test
Test Suites: 64 passed, 64 total
Tests: 145 passed, 145 total
```

---

## POST-HOOK Validation

\```bash
$ bash scripts/hooks/post-backend-wave-2.sh
🔍 POST-HOOK VALIDATION for Wave 2
✅ GATE 1: Compilation (0 errors)
✅ GATE 2: Tests (145/145 passing)
✅ GATE 3: Coverage (100%)
✅ GATE 4: Linting (clean)
✅ FLAG CREATED: wave-2-backend-complete.flag
✅✅✅ POST-HOOK PASSED ✅✅✅
\```

**Exit Code**: 0
**Status**: ✅ COMPLETE

### Evidence:
- Flag: `scripts/hooks/gate-flags/wave-2-backend-complete.flag` ✅
- Tests: 145/145 passing (100%)
- Coverage: 100%
- Compilation: 0 errors

---

## Conclusion

Wave 2 (Application Layer) is **COMPLETE** according to POST-HOOK validation.
Ready to proceed to Wave 3 (API Layer).
```

---

## 🔄 FIX-RETEST LOOP

**If POST-HOOK fails**, you MUST enter this loop:

```bash
while [ POST_HOOK_EXIT_CODE -ne 0 ]; do
  # 1. Identify which gate failed
  echo "POST-HOOK failed - analyzing..."

  # 2. Fix the failing gate
  #    - Tests failing? → Fix test/implementation
  #    - Coverage low? → Add tests
  #    - Linting errors? → Run eslint --fix
  #    - Compilation? → Fix TypeScript errors

  # 3. Re-run tests/build
  npm test
  npm run build
  npm run lint

  # 4. Re-run POST-HOOK
  bash scripts/hooks/post-backend-wave-X.sh
  POST_HOOK_EXIT_CODE=$?
done

echo "✅ POST-HOOK passed - Wave complete"
```

**NEVER report "complete" while in this loop. ONLY when exit code = 0.**

---

## 🎯 AGENT-SPECIFIC MAPPINGS

### 10-Backend-Development-Agent
- **Wave 1**: `pre/post-backend-wave-1.sh` (Domain)
- **Wave 2**: `pre/post-backend-wave-2.sh` (Application)
- **Wave 3**: `pre/post-backend-wave-3.sh` (API)

### 11-Frontend-Development-Agent
- **Wave 4**: `pre/post-frontend-wave-4.sh` (Frontend)

### 13-Backend-Test-Agent
- **Integration**: `pre/post-backend-integration-test.sh`

### 14-Frontend-Test-Agent
- **Unit Tests**: `pre/post-frontend-tests.sh`

### 15-Integration-Test-Agent
- **Integration**: `pre/post-backend-integration-test.sh`

### 16-E2E-Test-Agent
- **E2E**: `pre/post-e2e-test.sh`

---

## 📊 SUCCESS METRICS

**Wave is ONLY complete when**:

1. ✅ PRE-HOOK passed (exit 0)
2. ✅ Work implemented
3. ✅ Tests written and passing
4. ✅ POST-HOOK passed (exit 0)
5. ✅ Flag created
6. ✅ Report includes full hook outputs

**If ANY of these is missing → Wave is INCOMPLETE**

---

## 🔒 NON-NEGOTIABLE RULES

```
1. MUST run PRE-HOOK before starting
2. MUST run POST-HOOK after finishing
3. MUST include full hook output in reports
4. MUST fix issues if hooks fail
5. MUST create flags as evidence
6. MUST mark complete ONLY when exit code = 0
7. CANNOT skip hooks
8. CANNOT summarize hooks
9. CANNOT self-validate without hooks
10. CANNOT mark complete with failing hooks
```

**Breaking any of these rules = Work REJECTED**

---

**Created**: 2026-03-31
**Version**: 1.0.0 (Capa 1 - Agent Enforcement)
**Part of**: Quality Enforcement Framework
**Complements**: `.claude/agent-config.md` (specific agent rules)
