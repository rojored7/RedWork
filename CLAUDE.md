# CLAUDE.md - RedWork Framework v2.1

Instructions for Claude Code when working with this framework repository.

---

## This is the Framework Repository

This repo contains the framework itself (agents, skills, scripts, stacks).
**DO NOT develop application code here.** Use `python install.py init <name>` to create projects.

---

## Installation (Global)

```bash
python install.py install --profile full
```

Installs to `~/.claude/redwork/`. Agents, skills, and scripts are shared globally.

## Create a Project

```bash
python install.py init my-project --backend fastapi --frontend react
cd ../my-project
git remote add origin <gitlab-url>
git push -u origin main
```

Projects get ONLY: outputs/, .project-state/, .gitlab-ci.yml, CLAUDE.md. No framework copy.

---

## Agent Sequence (01-25)

```
PREVAL:     00b impact-prevalidator (hard gate: validate-impact-analysis.sh)
DISCOVERY:  01 -> 02 -> 03 -> 04 [04b] -> 05 [05b]
PLANNING:   06 -> 07 -> 08 -> 09
API:        10 -> 11
ORCHESTR:   25 (Phase 0 activates hooks, then manages waves)
INFRA:      12
BACKEND:    13 (tests first, TDD Red) -> 14 (make tests pass, TDD Green)
FRONTEND:   15 (tests first, TDD Red) -> 16 (make tests pass, TDD Green)
VALIDATION: 17 -> 18 -> 19 -> 20 -> 21
QUALITY:    22 -> 23 -> 24
```

Waves 3a/5a (backend/frontend tests) run in PARALLEL.
See AGENT_SEQUENCE.md for full dependency graph.

## Execute an Agent

```
User: "lanza el agente 01-product-discovery quiero un LMS"
Output: outputs/01_product_discovery.md
```

Each agent reads its predecessors' outputs and generates its own.
State is tracked in `.project-state/state.json`.

---

## Rules

See `rules/` directory for modular, distributable rules:

- `rules/common/` - Framework-wide rules (no emojis, TDD, agent sequence)
- `rules/fastapi/` - FastAPI stack constraints
- `rules/react/` - React stack constraints

Rules are copied to projects on `install.py init` (common + stack-specific).

---

## Slash Commands (Flows)

`commands/` ships three orchestration flows, installed to `~/.claude/commands/`:

| Command | Purpose |
|---|---|
| `/flow-new-project` | Full DDD pipeline from idea to deployment (agents 01-25) |
| `/flow-update` | Add a feature / update an existing project (Docker-aware, TDD slices) |
| `/flow-bugfix` | Diagnose and fix a bug with a reproducing test first |

The flows orchestrate the numbered RedWork agents (01-25) plus 9 ambient agents
(`code-explorer`, `code-architect`, `planner`, `tdd-guide`, `code-reviewer`,
`security-reviewer`, `python-reviewer`, `typescript-reviewer`,
`build-error-resolver`) and the `plan-critic` agent. The ambient agents are
**vendored in `agents/ambient/`** (upstream: ECC) and `install.py install` copies
them to `~/.claude/agents/` — ECC is NOT a prerequisite. See
`agents/ambient/README.md` for the sync rule.

### impact-prevalidator (total-impact pre-validation, hard gate)

`agents/impact-prevalidator.md` runs FIRST in every flow (Fase 0), BEFORE exploring
or planning. It maps everything the change would affect against the real repo:
blast radius (inverse deps), data layer/migrations, Docker COPY-vs-volume, API
contracts, test baseline. Emits `outputs/00b_impact_analysis.md` anchored to HEAD
with a VERDE/AMARILLO/ROJO verdict, enforced by
`scripts/workflow/validate-impact-analysis.sh` (exit 0 fresh VERDE / AMARILLO with
--allow-amber; 1 blocked; 2 missing; 3 malformed; 4 stale). Agent 25 Phase 0
check 0.6 re-verifies it: no fresh report, no development.

### plan-critic (adversarial plan gate)

`agents/plan-critic.md` critiques a plan BEFORE implementation, trying to refute it
against the real codebase (missing dependencies, wrong ordering, unverified
assumptions, forgotten migrations/rebuild/rollback). Returns
APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO with concrete evidence. It runs at
the single human gate of `/flow-update` (step 4.5), which presents impact verdict +
plan + critique together.

---

## Execution Doctrine (approved plan = execute 100%)

An approved plan is **full authorization** to execute it end to end.

- Run every step of the approved plan without asking for intermediate confirmation.
  Do NOT ask "continue?" / "proceed?" for steps already in the approved plan.
- Stop ONLY if: (a) an automatic gate fails and fixing it requires leaving the plan;
  (b) a destructive/irreversible action not covered by the plan appears; (c) you
  discover something that changes the real scope. In those cases stop with context and
  concrete options — not a vague question.
- If a step fails: try to resolve it within the plan's scope (retries,
  build-error-resolver) BEFORE escalating.
- On finish: ONE consolidated report — what was done, verification evidence,
  deviations from the plan.

The flows implement this as **a single human gate** (impact verdict + plan +
plan-critic critique), then continuous execution with automatic gates (tests green,
linting, smoke) as the only advance condition.

**Bounded retries (factory loop):** wave gates run through
`scripts/workflow/run-gates.sh <wave>`, which shares a persistent retry counter
(`.project-state/retry_state.json`, cap `FRAMEWORK_MAX_RETRIES`, default 3) with the
post-commit hook. Gate pass clears `wave_N_blocked.flag` automatically; exhausting
the retries creates `needs_human.flag` and the loop STOPS with a consolidated report
(attempts, evidence per attempt, concrete options). Ask
`"$PYTHON_BIN" scripts/lib/retry_controller.py next` for the machine-readable next
action (`run_agent | retry_gate | escalate_human | done`).

---

## Key Commands

| Command | Purpose |
|---|---|
| `python install.py install` | Install framework globally |
| `python install.py init <name>` | Create new project |
| `python install.py update` | Update to latest version |
| `python install.py status` | Show installation info |
| `python scripts/workflow/new_sprint.py N [--force]` | Generate sprint N pipeline |
| `bash scripts/workflow/validate-impact-analysis.sh --allow-amber` | Impact hard gate (00b) |
| `bash scripts/workflow/run-gates.sh <wave>` | Re-run a wave gate (bounded retries) |
| `python scripts/lib/retry_controller.py next` | Next factory-loop action |
| `python -m pytest tests/ -v` | Run framework tests |

---

## File Structure

```
Framework/
  install.py                    # Global installer
  AGENT_SEQUENCE.md             # Dependency graph
  agents/                       # 25 numbered + auxiliary agents (incl. impact-prevalidator, plan-critic)
  commands/                     # Slash-command flows (flow-new-project, flow-update, flow-bugfix)
  rules/                        # Modular rules (common + stack-specific)
  skills/                       # 14 skill documents
  scripts/
    lib/                        # Python libs (state, metrics, stack, paths, retry_controller) + python-detect.sh
    workflow/                   # Validators, gates (validate-impact-analysis, run-gates), auto-commit, sprints
    hooks/                      # Git hooks (post-commit v2, post-wave-*)
  stacks/                       # Stack configs (fastapi, react)
  .claude/
    settings.json               # Runtime hooks configuration
    hooks/                      # Claude Code hooks (session, pre-write, pre-bash, etc.)
  tests/                        # Framework tests
  manifests/                    # Installation profiles
  .gitlab-ci.yml               # Pipeline v3.0 with test-framework stage
```

---

## Multi-Sprint

```bash
python scripts/workflow/new_sprint.py 2
```

Generates `.gitlab/ci/sprint-2.yml` from template with parallel waves.
State.json tracks multiple sprints and wave progress.

---

Version: 2.2.0
