# Agent Analysis - Output and Validation Requirements

Analysis of all 20 agents to design proper workflow integration.

---

## PHASE 1: DISCOVERY & DESIGN (Agents 01-05)

### Agent 01: Product Discovery
- **Output**: `01_product_discovery.md` (single file)
- **Validation**: File exists and has required sections
- **Completion Check**:
  ```bash
  test -f 01_product_discovery.md && grep -q "Product Vision" 01_product_discovery.md
  ```
- **Hook**: None (creates initial documentation)
- **Git Action**: Commit file when complete

---

### Agent 02: Domain Modeling
- **Output**: `02_domain_model.md` (single file)
- **Validation**: File exists with entities, value objects, aggregates
- **Completion Check**:
  ```bash
  test -f 02_domain_model.md && grep -q "Domain Entities" 02_domain_model.md
  ```
- **Hook**: None
- **Git Action**: Commit file when complete

---

### Agent 03: Context Mapping
- **Output**: `03_context_map.md` (single file)
- **Validation**: File exists with bounded contexts defined
- **Completion Check**:
  ```bash
  test -f 03_context_map.md && grep -q "Bounded Contexts" 03_context_map.md
  ```
- **Hook**: None
- **Git Action**: Commit file when complete

---

### Agent 04: Architecture Decision
- **Output**: `04_architecture_decision.md` (single file)
- **Validation**: File exists with architecture decisions
- **Completion Check**:
  ```bash
  test -f 04_architecture_decision.md && grep -q "Architecture Pattern" 04_architecture_decision.md
  ```
- **Hook**: None
- **Git Action**: Commit file when complete

---

### Agent 05: Service Design
- **Output**: `05_service_design.md` (single file)
- **Validation**: File exists with service layer definitions
- **Completion Check**:
  ```bash
  test -f 05_service_design.md && grep -q "Clean Architecture" 05_service_design.md
  ```
- **Hook**: None
- **Git Action**: Commit file when complete

---

## PHASE 2: PLANNING (Agents 06-09)

### Agent 06: Epic Generation
- **Output**: `06_epics/*.md` (multiple files, one per epic)
- **Validation**: Directory exists with at least 1 epic file
- **Completion Check**:
  ```bash
  test -d 06_epics && [ $(ls -1 06_epics/*.md 2>/dev/null | wc -l) -gt 0 ]
  ```
- **Hook**: None
- **Git Action**: Commit all epic files when complete

---

### Agent 07: User Story Generation
- **Output**: `07_user_stories/**/*.md` (nested structure by epic)
- **Validation**: Directory exists with user stories
- **Completion Check**:
  ```bash
  test -d 07_user_stories && find 07_user_stories -name "*.md" | grep -q .
  ```
- **Hook**: None
- **Git Action**: Commit all user story files when complete

---

### Agent 08: Tech Lead Delivery
- **Output**: `08_implementation_breakdown/**/*.md` (breakdown per story)
- **Validation**: Directory exists with implementation breakdown
- **Completion Check**:
  ```bash
  test -d 08_implementation_breakdown && find 08_implementation_breakdown -name "*.md" | grep -q .
  ```
- **Hook**: None
- **Git Action**: Commit all breakdown files when complete

---

### Agent 09: Sprint Orchestrator
- **Output**: `09_sprint_plan/sprint_XX/*.md` (sprint plans)
- **Validation**: Sprint directory exists with execution plans
- **Completion Check**:
  ```bash
  find 09_sprint_plan -type d -name "sprint_*" | grep -q . && \
  find 09_sprint_plan -name "*.md" | grep -q .
  ```
- **Hook**: None
- **Git Action**: Commit all sprint plan files when complete

---

## PHASE 3: INFRASTRUCTURE (Agent 12)

### Agent 12: Infrastructure Deployment
- **Output**:
  - `docker-compose.yml`
  - `Dockerfile` (multiple)
  - `.project-orchestration/runtime-infrastructure.json`
- **Validation**:
  - Files exist
  - Docker services start successfully
  - Healthchecks pass
- **Completion Check**:
  ```bash
  test -f docker-compose.yml && \
  docker-compose ps | grep -q "Up" && \
  docker-compose ps | grep -q "healthy"
  ```
- **Hook**: `scripts/validate-infrastructure.sh`
- **Git Action**: Commit infrastructure files + validation report

---

## PHASE 4: DEVELOPMENT (Agents 10-11, 13-14, 20)

### Agent 10: Backend Development
- **Output**:
  - `backend/src/**/*.ts` (source code)
  - Implementation following Clean Architecture
- **Validation**:
  - Code compiles (npm run build = 0 errors)
  - Architecture validated
- **Completion Check**:
  ```bash
  cd backend && npm run build 2>&1 | grep -q "0 errors"
  ```
- **Hook**: `scripts/hooks/post-wave-3-backend.sh` (or similar)
- **Git Action**: Commit code + build report

---

### Agent 13: Backend Test
- **Output**:
  - `backend/**/*.spec.ts` (test files)
  - Test coverage report
- **Validation**:
  - Tests pass: 100%
  - Coverage: 100%
- **Completion Check**:
  ```bash
  cd backend && npm test 2>&1 | grep -q "Tests:.*100%" && \
  npm test -- --coverage | grep -q "100%"
  ```
- **Hook**: Backend test validation hook
- **Git Action**: Commit tests + coverage report

---

### Agent 11: Frontend Development
- **Output**:
  - `frontend/src/**/*.tsx` (source code)
  - React components, pages, services
- **Validation**:
  - Code compiles (npm run build = 0 errors)
  - Type check passes
- **Completion Check**:
  ```bash
  cd frontend && npm run build 2>&1 | grep -q "built in" && \
  npm run type-check 2>&1 | grep -q "0 errors"
  ```
- **Hook**: `scripts/hooks/post-wave-5-frontend.sh`
- **Git Action**: Commit code + build report

---

### Agent 14: Frontend Test
- **Output**:
  - `frontend/**/*.test.tsx` (test files)
  - Test coverage report
- **Validation**:
  - Tests pass: 100%
  - Coverage: 100%
- **Completion Check**:
  ```bash
  cd frontend && npm test 2>&1 | grep -q "100%" && \
  npm test -- --coverage | grep -q "100%"
  ```
- **Hook**: Frontend test validation hook
- **Git Action**: Commit tests + coverage report

---

### Agent 20: Linting Validator
- **Output**:
  - Linting reports
  - Fixed code (if lint --fix ran)
- **Validation**:
  - Backend: 0 errors, 0 warnings
  - Frontend: 0 errors, 0 warnings
- **Completion Check**:
  ```bash
  cd backend && npm run lint 2>&1 | grep -q "0 errors" && \
  cd frontend && npm run lint 2>&1 | grep -q "0 errors"
  ```
- **Hook**: Linting validation (may be part of pre-commit)
- **Git Action**: Commit linting report

---

## PHASE 5: TESTING (Agents 15-16, 18)

### Agent 15: Integration Test Validator
- **Output**:
  - `backend/test/integration/**/*.spec.ts` (integration tests)
  - Integration test report
- **Validation**:
  - Integration tests: 100% passing
  - Backend <-> DB validated
- **Completion Check**:
  ```bash
  cd backend && npm run test:integration 2>&1 | grep -q "100%"
  ```
- **Hook**: `scripts/post-hook-integration-tests.sh`
- **Git Action**: Commit integration tests + report

---

### Agent 16: E2E Test Validator
- **Output**:
  - E2E test files (Playwright)
  - E2E test report with screenshots
- **Validation**:
  - E2E tests: 100% passing
  - User flows validated
- **Completion Check**:
  ```bash
  npx playwright test 2>&1 | grep -q "100%"
  ```
- **Hook**: `scripts/post-hook-e2e-tests.sh`
- **Git Action**: Commit E2E tests + report + screenshots

---

### Agent 18: Smoke Test Validator
- **Output**:
  - Smoke test report
  - Critical path validation results
- **Validation**:
  - All critical paths work
  - Real execution verified
- **Completion Check**:
  ```bash
  bash scripts/smoke-test.sh 2>&1 | grep -q "PASSED"
  ```
- **Hook**: Smoke test validator script
- **Git Action**: Commit smoke test report

---

## PHASE 6: QUALITY & SECURITY (Agents 19-20)

### Agent 19: Security Review
- **Output**:
  - Security review report
  - List of findings (CRITICAL, HIGH, MEDIUM, LOW)
- **Validation**:
  - 0 CRITICAL findings
  - 0 HIGH findings
- **Completion Check**:
  ```bash
  test -f security-review-report.md && \
  grep -q "CRITICAL: 0" security-review-report.md && \
  grep -q "HIGH: 0" security-review-report.md
  ```
- **Hook**: Security validation script
- **Git Action**: Commit security report

---

### Agent 20: Final Linting
- **Output**:
  - Final linting report
  - Code quality summary
- **Validation**:
  - 0 errors across entire codebase
  - 0 warnings across entire codebase
- **Completion Check**:
  ```bash
  npm run lint 2>&1 | grep -q "0 errors.*0 warnings"
  ```
- **Hook**: Final linting validation
- **Git Action**: Commit final quality report

---

## Summary Table

| Agent | Type | Output | Validation | Hook Exists |
|-------|------|--------|------------|-------------|
| 01 | Document | Single file | File exists | No |
| 02 | Document | Single file | File exists | No |
| 03 | Document | Single file | File exists | No |
| 04 | Document | Single file | File exists | No |
| 05 | Document | Single file | File exists | No |
| 06 | Documents | Multiple files | Dir + files exist | No |
| 07 | Documents | Nested structure | Dir + files exist | No |
| 08 | Documents | Nested structure | Dir + files exist | No |
| 09 | Documents | Sprint plans | Dir + files exist | No |
| 12 | Infrastructure | Docker files + config | Services healthy | Yes |
| 10 | Code | Backend source | Compiles 0 errors | Yes |
| 13 | Tests | Backend tests | 100% coverage | Yes |
| 11 | Code | Frontend source | Compiles 0 errors | Yes |
| 14 | Tests | Frontend tests | 100% coverage | Yes |
| 20 | Validation | Linting report | 0 errors/warnings | Partial |
| 15 | Tests | Integration tests | 100% passing | Yes |
| 16 | Tests | E2E tests | 100% passing | Yes |
| 18 | Validation | Smoke test report | All paths pass | Yes |
| 19 | Report | Security report | 0 CRITICAL/HIGH | Yes |
| 20 | Report | Final quality report | 0 errors/warnings | Yes |

---

## Workflow Integration Strategy

Based on this analysis, we have 3 types of agents:

### Type A: Document Generators (01-09)
- **Validation**: Simple file existence check
- **Hook**: None needed
- **Workflow Update**: After commit, update status to "completed"

### Type B: Code/Infrastructure (10-12)
- **Validation**: Compilation + existing hooks
- **Hook**: Already exists in scripts/hooks/
- **Workflow Update**: Hook passes (exit 0) -> commit + update status

### Type C: Test/Validation (13-20)
- **Validation**: Tests pass 100% + existing hooks
- **Hook**: Already exists (integration, e2e, smoke, security)
- **Workflow Update**: Hook passes (exit 0) -> commit report + update status

---

## Next Steps

1. Create `workflow-status.json` tracker
2. Add workflow update logic to existing hooks
3. Configure GitLab to read status and update pipeline visualization
4. Test with Agent 01 first

---

Created: 2026-03-31
Purpose: Analyze agent requirements for workflow integration
