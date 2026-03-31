# ⚠️ READ THIS FIRST: AUTOMATIC HOOK ENFORCEMENT
**Before reading agent-specific rules, ALL agents MUST read:**
→ `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` ← **MANDATORY**

This file defines universal PRE-HOOK and POST-HOOK requirements.

---

# Agent Configuration for Task Manager Project

---

## 🔒 MANDATORY FOR ALL AGENTS: HOOK ENFORCEMENT

### CRITICAL RULE: Agents Do NOT Self-Validate

**PROBLEM IDENTIFIED**: Agents were reporting "100% complete" without actual validation.

**SOLUTION**: HOOKS validate completion, NOT agents.

### Universal POST-HOOK Requirement

**EVERY agent that creates/modifies code or tests MUST**:

1. **Execute POST-HOOK after work completes**
   ```bash
   # Backend agents:
   ./scripts/hooks/post-backend-wave-{N}.sh

   # Frontend agents:
   ./scripts/hooks/post-frontend-wave-{N}.sh

   # Test agents:
   ./scripts/hooks/post-{test-type}.sh
   ```

2. **Include POST-HOOK output in report**
   ```markdown
   ## POST-HOOK Validation
   ```bash
   $ ./scripts/hooks/post-backend-wave-2.sh
   [ACTUAL COMMAND OUTPUT HERE - NOT SUMMARY]
   ```

   **Exit Code**: 0 (success) or 1 (failure)
   **Status**: ✅ PASSED or ❌ FAILED
   ```

3. **Mark work as complete ONLY if POST-HOOK exits 0**
   - ✅ If hook exits 0 → Report "COMPLETE"
   - ❌ If hook exits 1 → Report "BLOCKED - fixing issues" and continue fixing

### Forbidden Patterns

❌ **NEVER report without hook validation**:
```markdown
## Test Results
All tests passing (100%)  ← WRONG! No hook output shown
```

❌ **NEVER summarize hook output**:
```markdown
## POST-HOOK Validation
Hook passed successfully  ← WRONG! Show actual output
```

❌ **NEVER claim completion if hook fails**:
```markdown
## POST-HOOK Validation
Hook exit code: 1  ← FAILURE
Status: ✅ Complete  ← WRONG! Cannot be complete if hook fails
```

✅ **CORRECT reporting**:
```markdown
## POST-HOOK Validation
```bash
$ ./scripts/hooks/post-backend-wave-2.sh
✅ GATE 1: Backend Compilation - PASSED
✅ GATE 2: Unit Tests (100%) - PASSED
✅ GATE 3: Integration Tests (100%) - PASSED
✅ GATE 4: Linting (0 errors) - PASSED
✅ POST-HOOK PASSED - Wave 2 COMPLETE
```

**Exit Code**: 0
**Status**: ✅ COMPLETE
```

### Agent Responsibility vs Hook Responsibility

| Responsibility | Agent | Hook |
|----------------|-------|------|
| Write code | ✅ Agent | ❌ |
| Run tests | ✅ Agent executes command | ❌ |
| Validate test results | ❌ | ✅ Hook |
| Determine if work complete | ❌ | ✅ Hook |
| Report hook output | ✅ Agent includes it | ❌ |
| Create success flags | ❌ | ✅ Hook |

**Summary**:
- Agents DO the work and run commands
- Hooks VALIDATE the work and decide if complete
- Agents REPORT what hooks say (not their own opinion)

### Enforcement

**If an agent report does NOT include**:
1. Actual POST-HOOK command execution
2. Full POST-HOOK output (not summary)
3. Hook exit code
4. Flag creation confirmation

**Then the report is REJECTED** and agent must fix and re-run.

---

## 08-Tech-Lead-Delivery-Agent Rules

### MANDATORY BEHAVIOR

When invoked for implementation breakdowns:

1. **COMPLETENESS REQUIREMENT**
   - Process ALL user stories found in 07_user_stories/
   - Create ALL 8 files for EACH story
   - Do NOT create summaries instead of detailed breakdowns
   - Do NOT skip any stories
   - Do NOT create "example" implementations

2. **OUTPUT STRUCTURE**
   ```
   08_implementation_breakdown/
   └── epic_XX_name/
       └── story_YYY_name/
           ├── 01_backend_tasks.md (REQUIRED)
           ├── 02_frontend_tasks.md (REQUIRED)
           ├── 03_database_tasks.md (REQUIRED)
           ├── 04_devops_tasks.md (REQUIRED)
           ├── 05_security_tasks.md (REQUIRED)
           ├── 06_qa_testing_tasks.md (REQUIRED)
           ├── 07_observability_tasks.md (REQUIRED)
           └── README.md (REQUIRED)
   ```

3. **VALIDATION CHECKLIST**
   Before completing, verify:
   - [ ] Count of folders created = Count of .md files in 07_user_stories/
   - [ ] Each folder contains exactly 8 files
   - [ ] Each file has detailed technical tasks (not summaries)
   - [ ] All files reference domain model, architecture, and service design

4. **NO TIME LIMITS**
   - Take as much time as needed
   - Process stories one by one if necessary
   - Quality over speed
   - Completeness is mandatory

5. **PROGRESS REPORTING**
   After each story completion, report:
   ```
   ✅ Story XX completed (Y/Z total)
   Files created: 8/8
   Next: Story XX+1
   ```

## Error Recovery

If interrupted:
- Resume from last completed story
- Do NOT recreate existing breakdowns
- Continue until ALL stories are done

## Quality Standards

Each breakdown file must contain:
- Minimum 15 specific, actionable tasks
- File paths and class names from service design
- Story point estimates
- Dependencies clearly identified
- Acceptance criteria for each task

---

## 09-Sprint-Orchestrator-Agent Rules

### CRITICAL: EPIC-DRIVEN SPRINT PLANNING

The sprint plan MUST be organized by **complete epics** that deliver business value. Each sprint folder is self-contained with ALL execution plans for the epics assigned to that sprint.

### MANDATORY OUTPUT STRUCTURE

```
09_sprint_plan/
├── sprint_01/
│   ├── sprint_goal.md (REQUIRED)
│   ├── sprint_overview.md (REQUIRED)
│   ├── backend_execution_plan.md (REQUIRED)
│   ├── frontend_execution_plan.md (REQUIRED)
│   ├── infrastructure_execution_plan.md (REQUIRED)
│   ├── dependency_map.md (REQUIRED)
│   ├── execution_waves.md (REQUIRED)
│   ├── excluded_items.md (REQUIRED)
│   └── CLAUDE.md (REQUIRED)
├── sprint_02/
│   ├── sprint_goal.md (REQUIRED)
│   ├── sprint_overview.md (REQUIRED)
│   ├── backend_execution_plan.md (REQUIRED)
│   ├── frontend_execution_plan.md (REQUIRED)
│   ├── infrastructure_execution_plan.md (REQUIRED)
│   ├── dependency_map.md (REQUIRED)
│   ├── execution_waves.md (REQUIRED)
│   ├── excluded_items.md (REQUIRED)
│   └── CLAUDE.md (REQUIRED)
├── sprint_03/
│   └── [same 9 files...]
├── sprint_NN/
│   └── [same 9 files...]
└── README.md (Master index of all sprints)
```

### MANDATORY BEHAVIOR

1. **EPIC-FIRST ORGANIZATION**
   - Each sprint delivers ONE OR MORE COMPLETE epics (100% functional)
   - NEVER split an epic across multiple sprints
   - If Epic 01 is in Sprint 1, ALL user stories of Epic 01 must be in Sprint 1
   - ALWAYS reference user stories by their ID (US-XXX)

2. **SPRINT FOLDER CONTENTS**

   Each `sprint_XX/` folder MUST contain exactly 9 files:

   **a) sprint_goal.md**
   ```markdown
   # Sprint X Goal

   ## Epics in This Sprint
   - Epic XX: [Name] (100% Complete)
   - Epic YY: [Name] (100% Complete)

   ## Business Value
   [What business value this sprint delivers]

   ## Success Metrics
   - [Measurable metric 1]
   - [Measurable metric 2]
   ```

   **b) sprint_overview.md**
   ```markdown
   # Sprint X Overview

   ## Epic XX: [Name]
   ### User Stories
   - US-XXX: [Title] (X pts)
   - US-XXX: [Title] (X pts)

   ## Epic YY: [Name]
   ### User Stories
   - US-YYY: [Title] (X pts)

   ## Total Story Points: XX
   ## Duration: 2 weeks
   ## Team Size: X developers
   ```

   **c) backend_execution_plan.md**
   ```markdown
   # Backend Execution Plan - Sprint X

   ## Epic XX: [Name]

   ### US-XXX: [Title]
   **From**: 08_implementation_breakdown/epic_XX/story_XXX/01_backend_tasks.md

   #### Tasks
   - [ ] BE-XXX-001: [Task description] (Xh)
   - [ ] BE-XXX-002: [Task description] (Xh)

   [List ALL backend tasks from 01_backend_tasks.md for EACH user story in this sprint]
   ```

   **d) frontend_execution_plan.md**
   ```markdown
   # Frontend Execution Plan - Sprint X

   ## Epic XX: [Name]

   ### US-XXX: [Title]
   **From**: 08_implementation_breakdown/epic_XX/story_XXX/02_frontend_tasks.md

   #### Tasks
   - [ ] FE-XXX-001: [Task description] (Xh)
   - [ ] FE-XXX-002: [Task description] (Xh)

   [List ALL frontend tasks from 02_frontend_tasks.md for EACH user story in this sprint]
   ```

   **e) infrastructure_execution_plan.md**
   ```markdown
   # Infrastructure Execution Plan - Sprint X

   ## Epic XX: [Name]

   ### US-XXX: [Title]
   **From**: 08_implementation_breakdown/epic_XX/story_XXX/04_devops_tasks.md

   #### Tasks
   - [ ] INFRA-XXX-001: [Task description] (Xh)
   - [ ] INFRA-XXX-002: [Task description] (Xh)

   [List ALL infrastructure/devops tasks from 04_devops_tasks.md for EACH user story in this sprint]
   ```

   **f) dependency_map.md**
   ```markdown
   # Dependency Map - Sprint X

   ## Epic Dependencies
   - Epic XX depends on: [None or list of epics from previous sprints]
   - Epic YY depends on: Epic XX (same sprint)

   ## User Story Dependencies
   - US-XXX depends on: [None or other US-XXX]
   - US-YYY depends on: US-XXX

   ## Critical Path
   [Sequence of tasks that cannot be parallelized]
   ```

   **g) execution_waves.md**
   ```markdown
   # Execution Waves - Sprint X

   ## Wave 1 (Week 1, Days 1-2)
   - Setup infrastructure for Epic XX
   - Backend foundation for US-XXX

   ## Wave 2 (Week 1, Days 3-5)
   - Backend development for US-XXX, US-YYY
   - Frontend development for US-XXX

   ## Wave 3 (Week 2, Days 1-3)
   - Frontend development for US-YYY
   - QA testing for US-XXX

   ## Wave 4 (Week 2, Days 4-5)
   - Final integration
   - Sprint review preparation
   ```

   **h) excluded_items.md**
   ```markdown
   # Excluded Items - Sprint X

   ## Deferred to Future Sprints
   - [User stories or features not included in this sprint]

   ## Rationale
   - [Why these items were excluded]
   ```

   **i) CLAUDE.md**
   ```markdown
   [Generated from .claude/SPRINT_PLAN_CLAUDE_TEMPLATE.md]
   [Sprint-specific instructions for development agents]
   ```

3. **TASK EXTRACTION RULES**

   When creating execution plans for a sprint, you MUST:

   **For backend_execution_plan.md:**
   - Read ALL user stories assigned to this sprint
   - For EACH user story, read: `08_implementation_breakdown/epic_XX/story_XXX/01_backend_tasks.md`
   - Extract ALL tasks from each file
   - Format as checkboxes with task IDs and time estimates
   - Group by Epic → User Story → Tasks

   **For frontend_execution_plan.md:**
   - Read ALL user stories assigned to this sprint
   - For EACH user story, read: `08_implementation_breakdown/epic_XX/story_XXX/02_frontend_tasks.md`
   - Extract ALL tasks from each file
   - Format as checkboxes with task IDs and time estimates
   - Group by Epic → User Story → Tasks

   **For infrastructure_execution_plan.md:**
   - Read ALL user stories assigned to this sprint
   - For EACH user story, read: `08_implementation_breakdown/epic_XX/story_XXX/04_devops_tasks.md`
   - Extract ALL tasks from each file
   - Format as checkboxes with task IDs and time estimates
   - Group by Epic → User Story → Tasks

4. **SPRINT ASSIGNMENT LOGIC**

   Decide how many sprints are needed:
   ```
   - Count total epics (15 in this project)
   - Estimate story points per epic
   - Calculate team velocity (typically 25-35 points per 2-week sprint)
   - Assign complete epics to sprints ensuring 100% completion

   Example:
   Sprint 1: Epic 01 (25 pts) → 1 epic
   Sprint 2: Epic 02 (32 pts) → 1 epic
   Sprint 3: Epic 03 (18 pts) + Epic 04 (15 pts) → 2 epics (total 33 pts)
   ```

5. **VALIDATION CHECKLIST**

   Before completing sprint plan generation, verify:
   - [ ] All sprints have their own folder (sprint_01/, sprint_02/, etc.)
   - [ ] Each sprint folder has exactly 9 files
   - [ ] backend_execution_plan.md lists ALL backend tasks from 08_implementation_breakdown for epics in that sprint
   - [ ] frontend_execution_plan.md lists ALL frontend tasks from 08_implementation_breakdown for epics in that sprint
   - [ ] infrastructure_execution_plan.md lists ALL devops tasks from 08_implementation_breakdown for epics in that sprint
   - [ ] No epic is split across multiple sprints
   - [ ] All user stories from 07_user_stories are assigned to a sprint
   - [ ] All US-XXX IDs are explicitly referenced
   - [ ] Each sprint delivers 100% complete epics

6. **DEPENDENCIES**
   - Map dependencies between EPICS
   - Example in dependency_map.md: "Epic 03 depends on Epic 01 (authentication required)"
   - Ensure dependent epics are in later sprints

7. **CLAUDE.md GENERATION**
   - Use the template from .claude/SPRINT_PLAN_CLAUDE_TEMPLATE.md
   - Customize for sprint-specific epics
   - Include sprint number and epic names
   - Provide clear Definition of Done for this sprint

### FORBIDDEN PATTERNS

❌ **DO NOT CREATE:**
```
09_sprint_plan/
├── sprint_overview.md (single file with all sprints mixed)
├── backend_execution_plan.md (all sprints mixed)
├── frontend_execution_plan.md (all sprints mixed)
└── execution_waves.md (global waves)
```

❌ **DO NOT SPLIT EPICS:**
```
Sprint 1: Epic 01 (Stories 1-3 only)
Sprint 2: Epic 01 (Stories 4-5) ← WRONG! Epic split across sprints
```

❌ **DO NOT MIX PARTIAL EPICS:**
```
Sprint 1:
  - Epic 01 (80% complete)
  - Epic 02 (20% complete)
← WRONG! Epics not 100% complete
```

✅ **CORRECT STRUCTURE:**
```
09_sprint_plan/
├── sprint_01/
│   ├── sprint_goal.md (Epic 01: Authentication)
│   ├── backend_execution_plan.md (ONLY Epic 01 backend tasks)
│   ├── frontend_execution_plan.md (ONLY Epic 01 frontend tasks)
│   └── [7 more files]
├── sprint_02/
│   ├── sprint_goal.md (Epic 02: Gestión Tareas)
│   ├── backend_execution_plan.md (ONLY Epic 02 backend tasks)
│   ├── frontend_execution_plan.md (ONLY Epic 02 frontend tasks)
│   └── [7 more files]
└── README.md
```

✅ **CORRECT EPIC ASSIGNMENT:**
```
Sprint 1: Epic 01 - Autenticación ✓ (100% Complete)
  - US-001: Registro Email ✓
  - US-002: Verificación Email ✓
  - US-003: Login ✓
  - US-004: OAuth ✓
  - US-005: Recuperación Password ✓
  [ALL user stories of Epic 01]

Sprint 2: Epic 02 - Gestión de Tareas ✓ (100% Complete)
  - US-010: Crear Tarea ✓
  - US-011: Editar Tarea ✓
  - US-012: Cambiar Estado ✓
  - US-013: Subtareas ✓
  - US-014: Archivos ✓
  - US-015: Comentarios ✓
  [ALL user stories of Epic 02]
```

### PROGRESS REPORTING

After each sprint folder creation, report:
```
✅ Sprint X created
   Epics: Epic XX, Epic YY (100% complete)
   User Stories: X stories
   Story Points: XX points
   Files: 9/9 created
   Location: 09_sprint_plan/sprint_0X/
Next: Sprint X+1
```

### ERROR RECOVERY

If interrupted:
- Resume from last completed sprint folder
- Do NOT recreate existing sprint folders
- Continue until ALL epics are assigned to sprints
- Verify completeness before finishing


---

## 10-Backend-Development-Agent Rules

### MANDATORY: POST-HOOK Execution After Each Wave

**CRITICAL**: This agent MUST run POST-HOOK after completing each wave of backend development.

#### Wave Completion Workflow

```
CODE IMPLEMENTATION → COMPILE → TESTS → POST-HOOK → FLAG CREATION → MARK WAVE COMPLETE
```

#### POST-HOOK Requirements by Wave

**Wave 1 (Domain Layer)**:
```bash
# After completing domain entities, VOs, and domain tests
./scripts/hooks/post-backend-wave-1.sh
```

**Wave 2 (Application Layer)**:
```bash
# After completing use cases, services, and application tests
./scripts/hooks/post-backend-wave-2.sh
```

**Wave 3 (API Layer)**:
```bash
# After completing controllers, DTOs, and API tests
./scripts/hooks/post-backend-wave-3.sh
```

#### POST-HOOK Validates

Each POST-HOOK validates:
- ✅ Backend compilation (0 errors)
- ✅ Unit tests (100% passing)
- ✅ Test coverage (100%)
- ✅ Linting (0 errors, 0 warnings)
- ✅ No regressions in previous waves

#### Exit Codes

- `0` = Wave complete → Create flag, mark complete
- `1` = Issues detected → FIX ISSUES, re-run hook

#### Mandatory Report Format

```markdown
## Wave X Completion Report

### Code Changes
- [List files created/modified]

### Compilation
```bash
$ npm run build
[ACTUAL OUTPUT]
Exit code: 0
```

### Unit Tests
```bash
$ npm test
[ACTUAL OUTPUT]
Test Suites: X passed, X total
Tests: X passed, X total
Exit code: 0
```

### POST-HOOK Validation
```bash
$ ./scripts/hooks/post-backend-wave-X.sh
[FULL HOOK OUTPUT - NOT SUMMARY]
Exit code: 0 or 1
```

### Flag Created
- ✅ `scripts/hooks/gate-flags/wave-X-backend-complete.flag`

### Status
- ✅ COMPLETE (only if POST-HOOK exit code = 0)
- ❌ BLOCKED (if POST-HOOK exit code = 1)
```

#### BLOCKER RULES

**🚫 CANNOT mark wave complete if**:
- ❌ Backend doesn't compile (build errors)
- ❌ Any unit test fails (<100% passing)
- ❌ Coverage < 100%
- ❌ Linting errors exist
- ❌ POST-HOOK exits 1
- ❌ Flag not created

**✅ CAN ONLY mark wave complete when**:
- ✅ Backend compiles (0 errors)
- ✅ All unit tests pass (100%)
- ✅ Coverage = 100%
- ✅ Linting clean (0 errors)
- ✅ POST-HOOK exits 0
- ✅ Flag created

---

## 11-Frontend-Development-Agent Rules

### MANDATORY: POST-HOOK Execution After Wave 4

**CRITICAL**: This agent MUST run POST-HOOK after completing Wave 4 (Frontend implementation).

#### Wave 4 Completion Workflow

```
COMPONENT IMPLEMENTATION → BUILD → TESTS → POST-HOOK → FLAG CREATION → MARK WAVE COMPLETE
```

#### POST-HOOK Execution

**After completing all frontend components, pages, and tests**:
```bash
./scripts/hooks/post-frontend-wave-4.sh
```

#### POST-HOOK Validates

- ✅ Frontend build succeeds (0 errors)
- ✅ Frontend unit tests (100% passing)
- ✅ Test coverage (100%)
- ✅ Linting (0 errors, 0 warnings)
- ✅ TypeScript compilation (0 errors)

#### Exit Codes

- `0` = Wave 4 complete → Create flag, mark complete
- `1` = Issues detected → FIX ISSUES, re-run hook

#### Mandatory Report Format

```markdown
## Wave 4 Frontend Completion Report

### Components Created/Modified
- [List files created/modified]

### Build
```bash
$ npm run build
[ACTUAL OUTPUT]
Exit code: 0
```

### Unit Tests
```bash
$ npm run test
[ACTUAL OUTPUT]
Test Files: X passed (X)
Tests: X passed (X)
Exit code: 0
```

### POST-HOOK Validation
```bash
$ ./scripts/hooks/post-frontend-wave-4.sh
[FULL HOOK OUTPUT - NOT SUMMARY]
Exit code: 0 or 1
```

### Flag Created
- ✅ `scripts/hooks/gate-flags/wave-4-frontend-complete.flag`

### Status
- ✅ COMPLETE (only if POST-HOOK exit code = 0)
- ❌ BLOCKED (if POST-HOOK exit code = 1)
```

#### BLOCKER RULES

**🚫 CANNOT mark Wave 4 complete if**:
- ❌ Frontend doesn't build (build errors)
- ❌ Any unit test fails (<100% passing)
- ❌ Coverage < 100%
- ❌ Linting errors exist
- ❌ TypeScript errors exist
- ❌ POST-HOOK exits 1
- ❌ Flag not created

**✅ CAN ONLY mark Wave 4 complete when**:
- ✅ Frontend builds (0 errors)
- ✅ All unit tests pass (100%)
- ✅ Coverage = 100%
- ✅ Linting clean (0 errors)
- ✅ TypeScript clean (0 errors)
- ✅ POST-HOOK exits 0
- ✅ Flag created

---

## 13-Backend-Test-Agent Rules (Integration Tests)

### MANDATORY: Hook System Integration

**CRITICAL**: This agent MUST execute hooks to validate prerequisites and results.

### ⚠️ NO SELF-REPORTING ALLOWED

**PROBLEM IDENTIFIED**: This agent previously reported "20/20 integration tests passing (100%)" when reality was only 16/20 (80%).

**ROOT CAUSE**: Agent claimed completion without running POST-HOOK to verify.

**SOLUTION**: Agent MUST run POST-HOOK and report its output. Agent's opinion is IRRELEVANT - only hook output matters.

#### What Agent CAN Do:
- ✅ Write test code
- ✅ Execute test command: `npm run test:integration`
- ✅ Execute POST-HOOK: `./scripts/hooks/post-backend-integration-test.sh`
- ✅ Report POST-HOOK output verbatim
- ✅ Copy exit code from POST-HOOK

#### What Agent CANNOT Do:
- ❌ Claim "tests passing" without hook verification
- ❌ Summarize hook output ("hook passed")
- ❌ Self-assess completion status
- ❌ Interpret test results differently than hook
- ❌ Mark complete if POST-HOOK exits 1

#### Hook Workflow

```
PRE-HOOK → TESTS EXECUTION → POST-HOOK → FLAG CREATION → MARK COMPLETE
```

### Step 1: Pre-Hook Validation (BLOCKING)

**Before ANY test execution**, run:

```bash
./scripts/hooks/pre-backend-integration-test.sh
```

**This pre-hook validates**:
- ✅ WAVE 3 (Backend API) complete (flag exists)
- ✅ Backend compiles (0 errors)
- ✅ Unit tests pass (100%)
- ✅ PostgreSQL running (healthy)
- ✅ Redis running (healthy)
- ✅ Backend application running (health check passes)

**Exit codes**:
- `0` = Prerequisites met → Continue
- `1` = Prerequisites NOT met → **BLOCKED** (cannot continue)

**If pre-hook fails**:
1. ❌ STOP immediately
2. 📝 Report which prerequisite failed
3. 🔧 Fix the failed prerequisite
4. 🔄 Re-run pre-hook
5. ✅ Only proceed when pre-hook exits 0

### Step 2: Execute Integration Tests

**Only if pre-hook passed**, execute:

```bash
cd backend
npm run test:integration
```

### Step 3: Post-Hook Validation (BLOCKING)

**After test execution**, run:

```bash
./scripts/hooks/post-backend-integration-test.sh
```

**This post-hook**:
- ✅ Parses test results
- ✅ Validates 100% passing (0 failures)
- ✅ Creates success flag: `integration-tests-complete.flag`
- ❌ BLOCKS if any test fails

**Exit codes**:
- `0` = Tests passing 100% → Can mark complete
- `1` = Tests failing → **BLOCKED** (cannot mark complete)

### Step 4: Fix-Retest Loop (MANDATORY)

**If post-hook fails**:

```bash
while [ $? -ne 0 ]; do
  # Analyze failures
  cat /tmp/integration-test-results-*.txt

  # Identify root cause:
  #  - Test code issue? → Fix test
  #  - Application bug? → Report to 10-Backend-Development-Agent

  # Fix issue
  # ...

  # Re-run tests
  cd backend
  npm run test:integration

  # Re-run post-hook
  ./scripts/hooks/post-backend-integration-test.sh
done
```

**Continue loop until post-hook exits 0 (100% passing).**

### Step 5: Verify Flag Creation

**Only mark work complete when**:

```bash
# Check flag exists
ls scripts/hooks/gate-flags/integration-tests-complete.flag

# ✅ Flag exists = Evidence of success
# ❌ Flag missing = Work NOT complete
```

### BLOCKER RULES

**🚫 CANNOT mark work complete if**:
- ❌ Pre-hook fails (exit code 1)
- ❌ Post-hook fails (exit code 1)
- ❌ Any test fails (<100% passing)
- ❌ Flag not created
- ❌ Justification: "infrastructure works but tests fail"
- ❌ Justification: "framework validated"

**✅ CAN ONLY mark complete when**:
- ✅ Pre-hook passes (exit code 0)
- ✅ Tests pass 100% (0 failures)
- ✅ Post-hook passes (exit code 0)
- ✅ Flag created: `integration-tests-complete.flag`

### Output Requirements

**Report MUST include**:

```markdown
## Integration Tests Execution Report

### Pre-Hook
- Status: ✅ PASSED
- Prerequisites: All met

### Test Execution
- Command: npm run test:integration
- Total Tests: X
- Passed: X (100%)
- Failed: 0
- Duration: X.Xs

### Post-Hook
- Status: ✅ PASSED
- Validation: 100% passing confirmed
- Flag Created: integration-tests-complete.flag

### Evidence
- Test output: /tmp/integration-test-results-XXXXX.txt
- Flag: scripts/hooks/gate-flags/integration-tests-complete.flag

### Status: ✅ COMPLETE
```

---

## 14-Frontend-Test-Agent Rules (Frontend Unit Tests)

### MANDATORY: Hook System Integration

**CRITICAL**: This agent MUST execute hooks to validate test results.

### ⚠️ NO SELF-REPORTING ALLOWED

**Agents do NOT decide if tests pass - HOOKS do.**

#### POST-HOOK Execution

**After auditing/fixing frontend unit tests**:
```bash
cd frontend
npm run test
./scripts/hooks/post-frontend-tests.sh
```

#### POST-HOOK Validates

- ✅ All frontend unit tests pass (100%)
- ✅ Test coverage = 100%
- ✅ No skipped tests
- ✅ No test.only or describe.only

#### Exit Codes

- `0` = Tests passing 100% → Mark complete
- `1` = Issues detected → FIX and re-run

#### Mandatory Report Format

```markdown
## Frontend Test Audit Report

### Test Execution
```bash
$ npm run test
[ACTUAL OUTPUT]
Test Files: X passed (X)
Tests: X passed (X)
```

### POST-HOOK Validation
```bash
$ ./scripts/hooks/post-frontend-tests.sh
[FULL HOOK OUTPUT - NOT SUMMARY]
Exit code: 0 or 1
```

### Status
- ✅ COMPLETE (only if POST-HOOK exit code = 0)
- ❌ BLOCKED (if POST-HOOK exit code = 1)
```

#### BLOCKER RULES

**🚫 CANNOT mark audit complete if**:
- ❌ Any test fails (<100%)
- ❌ Coverage < 100%
- ❌ POST-HOOK exits 1

**✅ CAN ONLY mark complete when**:
- ✅ All tests pass (100%)
- ✅ Coverage = 100%
- ✅ POST-HOOK exits 0

---

## 15-Integration-Test-Agent Rules (Full Stack Integration)

### MANDATORY: Hook System Integration

**CRITICAL**: This agent MUST execute hooks to validate integration between backend, database, and all services.

### ⚠️ NO SELF-REPORTING ALLOWED

**Agents do NOT decide if integration tests pass - HOOKS do.**

#### POST-HOOK Execution

**After creating/fixing integration tests**:
```bash
cd backend
npm run test:integration
./scripts/hooks/post-backend-integration-test.sh
```

#### POST-HOOK Validates

- ✅ All integration tests pass (100%)
- ✅ Backend running and healthy
- ✅ Database connections working
- ✅ Redis connections working
- ✅ All API endpoints responding correctly

#### Exit Codes

- `0` = Integration tests passing 100% → Create flag, mark complete
- `1` = Issues detected → FIX and re-run

#### Mandatory Report Format

```markdown
## Integration Test Report

### Test Execution
```bash
$ npm run test:integration
[ACTUAL OUTPUT]
Test Suites: X passed, X total
Tests: X passed, X total
```

### POST-HOOK Validation
```bash
$ ./scripts/hooks/post-backend-integration-test.sh
[FULL HOOK OUTPUT - NOT SUMMARY]
Exit code: 0 or 1
```

### Flag Created
- ✅ `scripts/hooks/gate-flags/integration-tests-complete.flag`

### Status
- ✅ COMPLETE (only if POST-HOOK exit code = 0)
- ❌ BLOCKED (if POST-HOOK exit code = 1)
```

#### BLOCKER RULES

**🚫 CANNOT mark integration tests complete if**:
- ❌ Any test fails (<100%)
- ❌ Backend not responding
- ❌ Database connection fails
- ❌ POST-HOOK exits 1
- ❌ Flag not created

**✅ CAN ONLY mark complete when**:
- ✅ All tests pass (100%)
- ✅ Infrastructure healthy
- ✅ POST-HOOK exits 0
- ✅ Flag created

---

## 16-E2E-Test-Agent Rules (Playwright Tests)

### MANDATORY: Hook System Integration

**CRITICAL**: This agent MUST execute hooks to validate prerequisites and results.

### ⚠️ NO SELF-REPORTING ALLOWED

**This agent has GOOD TRACK RECORD** - accurately reported 30/30 E2E tests passing in Sprint 2.

**KEY TO SUCCESS**: Agent ran actual Playwright tests and reported real results, not assumptions.

**CONTINUE THIS APPROACH**: Always execute POST-HOOK and report its output.

#### Hook Workflow

```
PRE-HOOK → E2E EXECUTION → POST-HOOK → FLAGS CREATION → WAVE 5 COMPLETE
```

### Step 1: Pre-Hook Validation (BLOCKING)

**Before ANY E2E test execution**, run:

```bash
./scripts/hooks/pre-e2e-test.sh
```

**This pre-hook validates**:
- ✅ WAVE 4 (Frontend) complete (flag exists)
- ✅ WAVE 3 (Backend API) complete (flag exists)
- ✅ Backend application running (health check)
- ✅ Frontend application running (accessibility check)
- ✅ Backend unit tests pass (100%)
- ✅ Frontend unit tests pass (100%)
- ✅ Frontend builds successfully (0 errors)
- ✅ Playwright installed

**Exit codes**:
- `0` = Prerequisites met → Continue
- `1` = Prerequisites NOT met → **BLOCKED** (cannot continue)

**If pre-hook fails**:
1. ❌ STOP immediately
2. 📝 Report which prerequisite failed
3. 🔧 Fix the failed prerequisite
4. 🔄 Re-run pre-hook
5. ✅ Only proceed when pre-hook exits 0

### Step 2: Execute E2E Tests

**Only if pre-hook passed**, execute:

```bash
cd frontend
npx playwright test
```

### Step 3: Post-Hook Validation (BLOCKING)

**After E2E execution**, run:

```bash
./scripts/hooks/post-e2e-test.sh
```

**This post-hook**:
- ✅ Parses Playwright results
- ✅ Validates 0 failures (100% passing)
- ✅ Creates success flags:
  - `e2e-tests-complete.flag`
  - `wave-5-complete.flag`
- ❌ BLOCKS if any test fails

**Exit codes**:
- `0` = E2E tests passing 100% → WAVE 5 complete
- `1` = E2E tests failing → **BLOCKED** (WAVE 5 NOT complete)

### Step 4: Fix-Retest Loop (MANDATORY)

**If post-hook fails**:

```bash
while [ $? -ne 0 ]; do
  # Review failure artifacts
  ls frontend/test-results/
  ls frontend/playwright-report/

  # Diagnose root cause:
  #  - Backend not running? → Check backend server
  #  - API errors (502, 401)? → Report to 10-Backend-Development-Agent
  #  - UI issues? → Report to 11-Frontend-Development-Agent
  #  - Test flaky? → Fix test code

  # Coordinate fix with appropriate agent
  # ...

  # Re-run E2E tests
  cd frontend
  npx playwright test

  # Re-run post-hook
  ./scripts/hooks/post-e2e-test.sh
done
```

**Continue loop until post-hook exits 0 (0 failures).**

### Step 5: Verify Flags Creation

**WAVE 5 is ONLY complete when BOTH flags exist**:

```bash
# Check E2E flag
ls scripts/hooks/gate-flags/e2e-tests-complete.flag

# Check WAVE 5 flag
ls scripts/hooks/gate-flags/wave-5-complete.flag

# ✅ Both exist = WAVE 5 COMPLETE
# ❌ Any missing = WAVE 5 NOT complete
```

### BLOCKER RULES

**🚫 CANNOT mark WAVE 5 complete if**:
- ❌ Pre-hook fails (exit code 1)
- ❌ Post-hook fails (exit code 1)
- ❌ Any E2E test fails (>0 failures)
- ❌ Flags not created
- ❌ Justification: "infrastructure works but tests fail"
- ❌ Justification: "framework validated"
- ❌ Justification: "tests executed"

**✅ CAN ONLY mark WAVE 5 complete when**:
- ✅ Pre-hook passes (exit code 0)
- ✅ E2E tests pass (0 failures, 100%)
- ✅ Post-hook passes (exit code 0)
- ✅ Both flags created:
  - `e2e-tests-complete.flag`
  - `wave-5-complete.flag`

### Output Requirements

**Report MUST include**:

```markdown
## E2E Tests Execution Report

### Pre-Hook
- Status: ✅ PASSED
- Prerequisites: All met
  - Backend running: localhost:XXXX
  - Frontend running: localhost:XXXX

### E2E Test Execution
- Command: npx playwright test
- Total Tests: X
- Passed: X
- Failed: 0
- Duration: X.Xm

### Test Artifacts
- Screenshots: frontend/test-results/
- Videos: frontend/test-results/
- HTML Report: frontend/playwright-report/

### Post-Hook
- Status: ✅ PASSED
- Validation: 0 failures confirmed
- Flags Created:
  - e2e-tests-complete.flag ✅
  - wave-5-complete.flag ✅

### Evidence
- Test output: /tmp/e2e-test-results-XXXXX.txt
- Flags: scripts/hooks/gate-flags/

### Status: ✅ WAVE 5 COMPLETE
```

### Common E2E Failures & Fixes

**502 Bad Gateway**:
→ Backend not running or not accessible
→ Fix: Check `curl http://localhost:3000/health`

**401 Unauthorized**:
→ Authentication issue
→ Fix: Check login flow, JWT generation

**Timeout**:
→ App taking too long
→ Fix: Check network, backend performance

**Element not found**:
→ UI structure changed
→ Fix: Update selectors in test

**Navigation failed**:
→ Routing issue
→ Fix: Check frontend routing configuration

---

## Hook System Summary

### For ALL Testing Agents (13, 15, 16)

**MANDATORY WORKFLOW:**

```
1. Execute PRE-HOOK
   ↓ (if exit 0)
2. Execute TESTS
   ↓
3. Execute POST-HOOK
   ↓ (if exit 1)
4. FIX ISSUES
   ↓
5. REPEAT steps 2-4 until POST-HOOK exits 0
   ↓
6. VERIFY FLAG CREATED
   ↓
7. MARK COMPLETE
```

**NON-NEGOTIABLE RULES:**

1. ✅ Pre-hook MUST pass before tests run
2. ✅ Post-hook MUST pass before marking complete
3. ✅ 100% passing required (or 0 failures for E2E)
4. ✅ Flags MUST be created as evidence
5. ❌ "Infrastructure works" ≠ Complete
6. ❌ "Framework validated" ≠ Complete
7. ❌ "Tests executed" ≠ Complete
8. ✅ "Tests PASSING 100%" = Complete
