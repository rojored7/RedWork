# CHANGELOG v2.0.0

**Release Date:** 2026-04-12
**Commits:** 12 (616b138..9820836)
**Files Changed:** 105
**Lines:** +6,726 / -2,940

---

## Overview

RedWork v2.0 is a complete restructuring of the framework to support large-scale projects.
The previous version (v1.x) had structural problems discovered during Sprint 1 of a test
project (GAIA): 65% task completion, automated machinery never activated, NestJS contamination
throughout, test-after instead of TDD, no state management, no recovery mechanism.

v2.0 addresses all of these with 8 major improvements across 4 phases.

---

## Breaking Changes

- `init-new-project.sh` **REMOVED** -- replaced by `python install.py init <name>`
- Agent numbering changed (05c -> 10, 09b -> 11, frontend-test 14 -> 15, etc.)
- `.framework/` directory no longer used in projects (global install at `~/.claude/redwork/`)
- All Jest/NestJS backend patterns replaced with pytest/FastAPI
- TDD order inverted: tests (13/15) now run BEFORE implementation (14/16)

---

## Commit History

### 616b138 - Wire framework automation machinery to prevent silent descope

Root cause fix from Sprint 1 post-mortem. The framework existed but its automated
hooks, validators, and completeness gates NEVER activated.

**Created:**
- `scripts/workflow/validate-sprint-completeness.sh` -- the missing structural piece.
  Diffs planned tasks (from `_tasks.md`) against actual repo files (`git ls-files`).
  Emits `outputs/compliance/sprint_NN_completeness.json`. Exit 0 = 100%, Exit 1 = missing.

**Rewritten:**
- `scripts/hooks/post-commit-workflow` (v2): detects task commits `[TASK-SN-XX-NNN]`,
  triggers post-wave-N hooks and completeness gate on wave completion
- `scripts/workflow/update-workflow-status.sh`: dynamic regeneration from filesystem,
  no self-commit (breaks infinite loop)
- `scripts/install-workflow-hooks.sh`: installs both post-commit (v2) and pre-commit
  (FastAPI mandate blocker)

**Modified:**
- Agent 25: Phase 0 blocking (5 mandatory checks before development starts)
- Agent 00: Phase 4b FastAPI Mandate Gate (aborts if backend != FastAPI)
- Agent 08: `### Expected Files:` convention mandatory per task
- `.gitlab-ci.yml`: LEGACY-TOLERANT mode removed, non-FastAPI stacks cause exit 1
- `validate-agent-22.sh` / `validate-agent-24.sh`: fixed obsolete output paths

---

### e08421a - Full UX design in frontend agent + Beautiful API DX in API-first agent

**Agent 16 (Frontend Development) -- complete rewrite:**
- Removed "You are not a UI designer" identity
- Added Phase 0: Design System Foundation (mandatory before any screen)
  - Color palette (primary/secondary/accent/neutral + semantic)
  - Typography scale (8 sizes with line-height + letter-spacing)
  - Spacing system (4px base, 13-step scale)
  - Border radius, shadows, breakpoints, motion tokens, z-index
- Added component visual standards table (16 components with variants and states)
- Added micro-interactions mandate (hover, modal scale+fade, skeleton shimmer, etc.)
- Added accessibility as design (WCAG AA, focus-visible, keyboard, reduced-motion)
- Success criteria: zero unstyled pages, skeleton loaders on async, responsive 3 breakpoints

**Agent 10 (API Specification) -- DX-First principles added:**
- 7 principles: Naming as Communication, Responses that Teach, Predictability over
  Cleverness, Discoverability, Elegant Versioning, Transparent Rate Limiting,
  Security without Friction
- Error responses now include `suggestion` field
- DX is first behavioral priority, not last

**New skills:**
- `skills/ux-design-system.md`: Tailwind config, CSS vars, component specs, patterns
- `skills/api-dx-design.md`: naming cheat sheet, envelopes, pagination, rate limiting

---

### cdd68ec - Update init-new-project.sh and README for v2 workflow

- `init-new-project.sh` updated to copy ALL v2 scripts (18+ workflow scripts, 3 post-wave
  hooks, templates, Claude Code hooks)
- Generated project README updated to v2 workflow (Agent 00 first, Agent 25 activates hooks)
- Framework README rewritten with "Setup on a New Machine" section

---

### 0ed61e7 - Add Claude Code runtime hooks (Level 1 enforcement)

Two-level enforcement architecture:

**Level 1 -- Claude Code Runtime Hooks (new):**
- `session-start.sh`: loads project context (sprint, wave, tasks, mandate) on session start
- `user-prompt-classify.sh`: warns if prerequisites missing or NestJS mentioned
- `pre-write-validate.sh`: BLOCKS .ts in backend, @nestjs deps, .project-state direct edits
- `pre-bash-validate.sh`: BLOCKS hook bypass, force push, nestjs installs, destructive ops
- `post-write-feedback.sh`: lint reminders, design system warnings, auto-commit hints
- `on-stop.sh`: persists session state, refreshes workflow-status.json
- `pre-compact.sh`: saves critical context before compaction, re-injected by SessionStart

**Level 2 -- Git hooks + CI/CD (unchanged, second line of defense)**

---

### bb5003c - Enforce TDD by design

The framework was doing test-after (code first, tests second). Fixed:

- Agent 25 Phase 6: TDD wave order (tests before code)
  - Wave 3a: Agent 13 writes pytest tests from specs (Red)
  - Wave 3b: Agent 14 implements FastAPI to make tests pass (Green)
  - Wave 5a: Agent 15 writes Vitest tests from specs (Red)
  - Wave 5b: Agent 16 implements React to make tests pass (Green)
- Agent 13: identity changed to "Test Architect", writes tests BEFORE code exists
- Agent 14: "Tests Already Exist" mandate, run pytest after each task
- Agent 15: same TDD mandate, default stack Vitest + Testing Library (Jest removed)
- Agent 16: same mandate, run vitest after each task

---

### 9ab3934 + f5e63e3 - Exhaustive NestJS/Express/Jest contamination cleanup

23 files cleaned across 2 batches:

- `skills/testing-patterns.md`: full rewrite (Jest -> pytest + Vitest, v2.0)
- `agents/11-implementation-contract.md`: 12 sections converted (TS -> Python)
- `agents/workflow-orchestrator/` (8 files): Express/Jest -> FastAPI/pytest
- `agents/04b, 05b, 07bis, 24, smoke-test, README`: surgical cleanup
- `skills/typescript-quality-standards.md`: jest.fn() -> vi.fn()
- `CHANGELOG_v1.4.0.md`: NestJS patterns -> FastAPI patterns

Post-cleanup verification: zero active contamination remaining. Only mentions in
prohibited/detection contexts (validate-no-nestjs-contamination.sh, architecture-decision.md).

---

### db3866a - RedWork v2.0 - Global install, state management, stacks, metrics, tests

8 improvements across 4 phases:

**Phase 1 -- Foundations:**
- `install.py`: global installer (install/update/uninstall/init/status)
  - Installs to `~/.claude/redwork/` (no per-project `.framework/` copy)
  - Projects get only: outputs/, .project-state/, CI, CLAUDE.md
  - Profiles: full, backend-only, frontend-only
- `manifests/`: profile definitions (full.json, backend-only.json, frontend-only.json)
- `AGENT_SEQUENCE.md`: visual dependency graph for all 25 agents
- `tests/`: framework test suite
  - `test_state_manager.py`: 13 tests (init, lifecycle, dependencies, resume, sprint)
  - `test_validators.py`: 8 tests (validators, hooks install)

**Phase 2 -- Robustness:**
- `scripts/lib/state_manager.py`: unified state tracking
  - Agent lifecycle (start/complete/fail) with dependency enforcement
  - Resume from any point (get_next_agent, resume_info)
  - Multi-sprint support (update_sprint, wave tracking)
- `scripts/workflow/new_sprint.py`: generates sprint-N CI from template

**Phase 3 -- Scale:**
- `.gitlab/ci/_sprint-template.yml`: parallelized waves
  - 3a (backend tests) || 5a (frontend tests) run in parallel
  - 3b || 5b run in parallel, validation waits for both
- `stacks/`: plugin system (fastapi, django, react, vue configs)
- `scripts/lib/stack_resolver.py`: reads project stack, loads config

**Phase 4 -- Quality:**
- `scripts/lib/metrics.py`: execution metrics in JSONL format
- `scripts/lib/resolve_paths.py`: global/local path resolution

---

### 7a20cdd - Unified agent numbering (01-25 sequential + auxiliaries)

30 agent files renamed to follow execution order:

| Old | New | Change |
|-----|-----|--------|
| context-mapping-agent.md | 03-context-mapping.md | Added number |
| architecture-decision.md | 04-architecture-decision.md | Added number |
| service-design-architect.md | 05-service-design.md | Added number |
| epic-generation.md | 06-epic-generation.md | Added number |
| user-story-generator.md | 07-user-story-generation.md | Added number |
| tech-lead-delivery.md | 08-tech-lead-delivery.md | Added number |
| sprint-orchestrator.md | 09-sprint-orchestrator.md | Added number |
| 05c-api-first-specification-agent.md | 10-api-specification.md | Renumbered |
| 09b-implementation-contract-generator-agent.md | 11-implementation-contract.md | Renumbered |
| infrastructure-deployment.md | 12-infrastructure-deployment.md | Added number |
| backend-test-agent.md | 13-backend-test.md | Added number |
| backend-fastapi-dev.md | 14-backend-development.md | Renamed |
| frontend-test-auditor.md | 15-frontend-test.md | Renumbered |
| frontend-development.md | 16-frontend-development.md | Added number |
| integration-test-validator.md | 17-integration-test.md | Added number |
| e2e-test-validator.md | 18-e2e-test.md | Renumbered |
| smoke-test-validator.md | 19-smoke-test.md | Renumbered |
| security-review-agent.md | 21-security-review.md | Renumbered |
| 00-project-type-detector.md | project-type-detector.md | Auxiliary |
| 06bis-configuration-analyzer.md | configuration-analyzer.md | Auxiliary |
| 07bis-hidden-complexity-analyzer.md | hidden-complexity-analyzer.md | Auxiliary |
| 04c-agent-introspection-debugging.md | agent-introspection-debugging.md | Auxiliary |
| 21-learning-agent.md | learning-agent.md | Auxiliary |

Also renamed 3 validator scripts and updated 34 files with cross-references.

---

### 315a392 - Complete v2.0 plan - hooks, CI, docs, remove legacy init

- Agent 25: multi-sprint + state.json integration
- Claude Code hooks: read state.json for phase/stack/sprint/wave info
- pre-write-validate.sh: respects explicit stack override from state.json
- `.gitlab-ci.yml`: added test-framework stage (runs BEFORE setup)
- CLAUDE.md: complete rewrite for v2.0
- README.md: updated for install.py
- `init-new-project.sh` **DELETED** (replaced by `python install.py init`)

---

### 1115aba - Static audit - fix 29 inconsistencies across framework

Findings from Level 1 (static) audit with 2 parallel exploration agents:

**Critical (5):**
- session-start.sh referenced deleted init-new-project.sh
- sprint-1.yml had ALL agent numbers wrong (10->14, 11->16, etc.)
- 3 post-wave hooks used npm/ESLint for Python backend (rewritten to pytest/ruff)
- Agent 25 used .framework/ paths (incompatible with global install)
- resume-development.sh used deprecated datetime.utcnow()

**Path fixes (8):** Added global path (~/.claude/redwork/) as first option in
post-commit-workflow, install-workflow-hooks.sh, on-stop.sh. Fixed .framework/
references in learning-agent, project-type-detector, post-write-feedback.

**Data fixes (4):** Added agents 10/11 to update-workflow-status.sh dict.
Fixed validate-git-setup.sh and validate-no-nestjs-contamination.sh references.

---

### 9820836 - Level 2 execution audit - 22 hook tests + 19 unit tests passing

`tests/test_hooks_execution.py`: 22 tests executing each Claude Code hook via
subprocess with simulated JSON input:

| Hook | Tests | Verified |
|------|-------|----------|
| pre-write-validate | 9 | .ts block, .py allow, @nestjs block, .project-state block, etc. |
| pre-bash-validate | 9 | force push block, nestjs install block, rm -rf block, pytest allow |
| session-start | 2 | JSON output, framework-repo detection |
| on-stop | 1 | Runs without error |
| pre-compact | 1 | Runs without error |

Level 2 execution audit results:
- install.py install: 104 files (34 agents, 14 skills, 31 scripts, 4 stacks)
- install.py init: state.json, CLAUDE.md, git, CI all correct
- Unit tests: 19/19 passed
- Hook tests: 22/22 passed
- Validators: correct exit codes for all scenarios

---

## File Structure (v2.0)

```
Framework/
  install.py                         # Global installer
  CLAUDE.md                          # Framework instructions
  README.md                          # Setup and usage guide
  AGENT_SEQUENCE.md                  # Dependency graph
  CHANGELOG_v2.0.md                  # This file
  agents/
    01-product-discovery.md          # Discovery (01-05b)
    02-domain-modeling.md
    03-context-mapping.md
    04-architecture-decision.md
    04b-security-by-design.md
    05-service-design.md
    05b-technical-design-validator.md
    06-epic-generation.md            # Planning (06-09)
    07-user-story-generation.md
    08-tech-lead-delivery.md
    09-sprint-orchestrator.md
    10-api-specification.md          # API Contract (10-11)
    11-implementation-contract.md
    12-infrastructure-deployment.md  # Infrastructure
    13-backend-test.md               # TDD Red (backend)
    14-backend-development.md        # TDD Green (backend)
    15-frontend-test.md              # TDD Red (frontend)
    16-frontend-development.md       # TDD Green (frontend)
    17-integration-test.md           # Validation (17-21)
    18-e2e-test.md
    19-smoke-test.md
    20-linting-validator.md
    21-security-review.md
    22-design-compliance.md          # Quality (22-24)
    23-quick-reference.md
    24-build-deploy.md
    25-development-orchestrator.md   # Orchestrator
    project-type-detector.md         # Auxiliaries
    configuration-analyzer.md
    hidden-complexity-analyzer.md
    agent-introspection-debugging.md
    learning-agent.md
    wsl-docker-orchestrator.md
  skills/                            # 14 skill documents
    ux-design-system.md              # NEW in v2.0
    api-dx-design.md                 # NEW in v2.0
    testing-patterns.md              # Rewritten for pytest/Vitest
    ...
  scripts/
    install-workflow-hooks.sh
    lib/
      __init__.py
      resolve_paths.py               # NEW: global/local path resolution
      state_manager.py               # NEW: unified state tracking
      stack_resolver.py              # NEW: multi-stack support
      metrics.py                     # NEW: execution metrics
    workflow/
      validate-sprint-completeness.sh  # NEW: the completeness gate
      new_sprint.py                    # NEW: multi-sprint generation
      auto-commit-task.sh
      update-workflow-status.sh        # Rewritten: dynamic, no self-commit
      validate-agent-01..05.sh
      validate-agent-22..24.sh
      ...
    hooks/
      post-commit-workflow             # Rewritten: v2 with wave detection
      post-wave-3-backend.sh          # Rewritten: pytest/ruff (was npm)
      post-wave-4-api.sh              # Rewritten: FastAPI smoke tests
      post-wave-5-frontend.sh         # Rewritten: hybrid (frontend npm + backend python)
  stacks/                             # NEW: multi-stack plugin system
    fastapi/config.yaml
    django/config.yaml
    react/config.yaml
    vue/config.yaml
  manifests/                          # NEW: installation profiles
    full.json
    backend-only.json
    frontend-only.json
  .claude/
    settings.json                     # Runtime hooks configuration
    hooks/                            # NEW: 7 Claude Code runtime hooks
      session-start.sh
      user-prompt-classify.sh
      pre-write-validate.sh
      pre-bash-validate.sh
      post-write-feedback.sh
      on-stop.sh
      pre-compact.sh
  .gitlab-ci.yml                      # v3.0 with test-framework stage
  .gitlab/ci/
    _sprint-template.yml              # NEW: parallelized wave template
    sprint-1.yml                      # Fixed agent numbers
    ...
  tests/                              # NEW: framework test suite
    conftest.py
    test_state_manager.py             # 13 tests
    test_validators.py                # 8 tests
    test_hooks_execution.py           # 22 tests
```

---

## Test Suite (41 tests)

| File | Tests | Coverage |
|------|-------|----------|
| test_state_manager.py | 13 | Init, lifecycle, dependencies, resume, sprint |
| test_validators.py | 6+2skip | Validators, hook install, completeness gate |
| test_hooks_execution.py | 22 | All 7 Claude Code hooks with simulated input |
| **Total** | **41** | |

CI stage `test-framework` runs all tests before any agent pipeline stage.

---

## Migration from v1.x

1. `git pull` the framework to get v2.0
2. `python install.py install --profile full` to install globally
3. For existing projects with `.framework/`:
   - The `.framework/` directory is no longer updated
   - Scripts now search `~/.claude/redwork/` first, `.framework/` as fallback
   - To fully migrate: delete `.framework/` and rely on global install
4. Agent numbers changed -- update any scripts that reference old names
5. TDD order changed -- tests must run BEFORE implementation agents

---

Version: 2.0.0
Date: 2026-04-12
