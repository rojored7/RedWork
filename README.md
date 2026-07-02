# Framework Agents v2 - Complete Development Automation

Automated workflow with 25+ specialized agents for full-stack development with GitLab CI/CD.

Backend: FastAPI (Python) exclusively. Frontend: Full UX design system. API: Beautiful DX-first.

---

## Setup on a New Machine

### 1. Clone and Install Globally

```bash
git clone https://gitlab.com/rojored7-group/redwork.git Framework
cd Framework
python install.py install --profile full
```

This installs RedWork to `~/.claude/redwork/` (global, shared across all projects).

### 2. Create a Project

```bash
python install.py init my-project
cd ../my-project
```

This creates ONLY local structure (outputs/, .project-state/, CI). No .framework/ copy.
Agents, skills, and scripts live globally in ~/.claude/redwork/.

### 3. Push to GitLab

```bash
git remote add origin <your-gitlab-repo-url>
git push -u origin main
```

### 4. Run Agents in Order

In Claude Code:

```
0) "lanza el agente impact-prevalidator"
   -> Maps total blast-radius BEFORE anything else (hard gate)
   -> Output: outputs/00b_impact_analysis.md (VERDE/AMARILLO/ROJO, HEAD-anchored)
   -> Gate: bash scripts/workflow/validate-impact-analysis.sh --allow-amber

a) "lanza el agente project-type-detector"
   -> Detects project type, validates FastAPI mandate
   -> Output: outputs/00_project_detection.md

b) "lanza el agente 01-product-discovery quiero un [IDEA]"
   -> Then agents 02, 03, 04, 05 (Discovery phase)

c) "lanza el agente 06-epic-generation"
   -> Then agents 07, 08, 09 (Planning phase)
   -> Then agents 10, 11 (API Contract phase)

d) "lanza el agente 25-development-orchestrator"
   -> Phase 0 installs git hooks v2 AUTOMATICALLY
   -> Activates completeness gate
   -> Runs development agents (10-14, 18-20) in wave order
```

**NO manual hook installation needed.** Agent 25 Phase 0 handles everything.

---

## How It Works (v2)

### Discovery + Planning (Agents 00-09)

You invoke each agent manually in sequence. Each generates a `.md` file in `outputs/`.

### Development (Agent 25 orchestrates)

Agent 25 is the single entry point for development. On first run:

```
Phase 0 — Framework Activation (BLOCKING)
  [OK] install-workflow-hooks.sh (installs pre-commit + post-commit v2)
  [OK] post-commit hook v2 marker verified
  [OK] 00_project_detection.md exists (FastAPI validated)
  [OK] validate-sprint-completeness.sh present
  [OK] validate-git-setup.sh passes
  >>> FRAMEWORK ACTIVATED <<<
```

Then Agent 25 reads the sprint plan and invokes development agents in wave order:
- Wave 0: Infrastructure (Agent 12) — once per group (compose, monitoring, logging, staging, backup, perf)
- Wave 3a: Backend TESTS first (Agent 13) — writes pytest from specs, all tests MUST fail (Red)
- Wave 3b: Backend implementation (Agent 10) — makes the tests pass (Green)
- Wave 4: API integration validation
- Wave 5a: Frontend TESTS first (Agent 14) — writes Vitest tests from specs, all tests MUST fail (Red)
- Wave 5b: Frontend implementation (Agent 11) — makes the tests pass (Green)

### Automatic Machinery (fires on every commit)

Once hooks are installed, every `git commit` triggers:

1. **Pre-commit hook**: blocks NestJS/Express/Spring contamination in `backend/`
2. **Post-commit hook v2**: detects task commits `[TASK-SN-XX-NNN]` and:
   - Updates `workflow-status.json` dynamically
   - Detects if the task closes a wave (all tasks in that wave completed)
   - If wave closed: runs `post-wave-N-*.sh` (linting, smoke tests, security)
   - If wave passed: runs `validate-sprint-completeness.sh` (tasks vs repo)
   - If 100% complete: clears the wave for next one

### Completeness Gate

`validate-sprint-completeness.sh` is the structural piece that prevents silent descope:
- Parses `09_sprint_plan/sprint_NN/*_tasks.md`
- Reads `### Expected Files:` section from each task
- Diffs expected files against actual repo tree via `git ls-files`
- Emits `outputs/compliance/sprint_NN_completeness.json`
- Exit 0 = 100% implemented, Exit 1 = missing tasks (wave blocked)

---

## Agent Sequence

```
00b Impact Prevalidator        (ALWAYS FIRST — hard gate validate-impact-analysis.sh)
00  Project Type Detector      (MANDATORY, validates FastAPI)
01  Product Discovery
02  Domain Modeling
03  Context Mapping
04  Architecture Decision
04b Security by Design
05  Service Design
05c API-First Specification    (Beautiful API with DX-first principles)
06  Epic Generation
07  User Story Generation
08  Tech Lead Delivery         (Expected Files per task — mandatory)
09  Sprint Orchestrator
09b Implementation Contract Generator
25  Development Orchestrator   (Phase 0: activates all machinery)
    |
    +-- 12  Infrastructure     (once per group, not once total)
    +-- 13  Backend TESTS FIRST (TDD Red phase — pytest from specs)
    +-- 10  Backend Dev        (TDD Green phase — makes tests pass)
    +-- 14  Frontend TESTS FIRST (TDD Red phase — Vitest from specs)
    +-- 11  Frontend Dev       (TDD Green phase — makes tests pass)
    +-- 18  Smoke Tests
    +-- 19  Security Review
    +-- 20  Linting Validator
15  Integration Tests
16  E2E Tests
22  Design Compliance
23  Quick Reference Generator
24  Build & Deploy Analyzer
```

---

## Framework Mandates

| Rule | Enforcement |
|---|---|
| Impact analysis before everything | `validate-impact-analysis.sh` blocks flows and Agent 25 (check 0.6) without a fresh HEAD-anchored `00b_impact_analysis.md`. |
| Bounded automatic retries | `run-gates.sh` + `retry_controller.py`: gate pass auto-clears `wave_N_blocked.flag`; `FRAMEWORK_MAX_RETRIES` (3) exhausted -> `needs_human.flag` + consolidated report. |
| Backend = FastAPI (Python) | Pre-commit hook blocks NestJS/TS. Pipeline setup exits 1. Project Type Detector marks UNSUPPORTED. |
| Frontend = Full UX design | Agent 11 requires Design System Phase 0 before any screen. No blank pages. |
| API = Beautiful DX | Agent 10 enforces 7 DX principles: naming, envelopes, suggestions in errors, etc. |
| Sprint completeness = 100% | `validate-sprint-completeness.sh` blocks wave if tasks are missing. |
| Author != Reviewer | Agent 25 mandates 15-frontend-test as independent pass after 16-frontend-development. |
| Tasks have Expected Files | Agent 08 must include `### Expected Files:` per task or completeness gate fails. |

---

## Key Files

```
Framework/
  install.py                       # Global installer (install/update/uninstall/init/status)
  .gitlab-ci.yml                   # Pipeline v3.0 (FastAPI mandate, no LEGACY-TOLERANT)
  .gitlab/ci/*.yml                 # Child pipeline definitions (8 stages)
  workflow-status.json             # Status template (regenerated dynamically)
  agents/                          # 25+ agent definitions
  agents/ambient/                  # 9 vendored flow actors (code-explorer, planner, tdd-guide, reviewers...) installed to ~/.claude/agents/
  skills/                          # 14 skill documents (including ux-design-system, api-dx-design)
  scripts/
    install-workflow-hooks.sh      # Installs pre-commit + post-commit v2
    hooks/
      post-commit-workflow         # framework-workflow-hook-v2 (wave detection + completeness)
      post-wave-3-backend.sh       # Backend validation (lint, smoke, security)
      post-wave-4-api.sh           # API validation
      post-wave-5-frontend.sh      # Frontend + system validation
    workflow/
      validate-sprint-completeness.sh   # THE completeness gate (tasks vs repo)
      auto-commit-task.sh               # Task commits with state tracking
      update-workflow-status.sh          # Dynamic JSON regeneration (no self-commit)
      validate-no-nestjs-contamination.sh  # FastAPI mandate for framework files
      validate-agent-*.sh               # Per-agent output validators
      validate-git-setup.sh             # Git repo health check
      resume-development.sh             # Resume after disconnect
```

---

## Troubleshooting

### "FRAMEWORK ACTIVATED" never appears

Agent 25 Phase 0 failed. Check which step failed:
- Missing `00_project_detection.md` -> run Project Type Detector first
- Hook marker missing -> delete `.git/hooks/post-commit` and re-run Agent 25
- `validate-sprint-completeness.sh` missing -> framework incomplete, re-run `python install.py install`

### Pre-commit rejects my commit

The pre-commit hook detected non-FastAPI code in `backend/`:
- TypeScript files under `backend/` -> remove them, use Python
- `@nestjs` in `backend/package.json` -> this project requires FastAPI
- To bypass (NOT recommended): `git commit --no-verify`

### Impact gate fails (exit 2/4/1)

- exit 2: no report -> run `lanza el agente impact-prevalidator`
- exit 4: report stale (HEAD moved) -> re-run the impact-prevalidator
- exit 1: verdict ROJO (or AMARILLO without --allow-amber) -> resolve the
  report's "Condiciones para VERDE" before planning

### Wave blocked

A `.project-state/wave_N_blocked.flag` file appeared. Fix within plan scope, then:
```bash
bash scripts/workflow/run-gates.sh <wave>
```
Exit 0 clears the flag and resets the retry counter automatically. Check:
- `outputs/compliance/sprint_NN_completeness.json` for missing tasks
- Post-wave report in `.project-orchestration/post-wave-N-report-*.md`
- `.project-state/retry_state.json` for attempts used
- If `needs_human.flag` exists: retries exhausted — a human decision is
  required; clear the flag only after deciding

### Sprint at < 100%

Run manually: `bash scripts/workflow/validate-sprint-completeness.sh 01`
The JSON report lists every task with status (implemented/missing/unverifiable).

---

Version: 2.2.0
Updated: 2026-07-02
