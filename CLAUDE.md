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
- `rules/django/` - Django stack constraints
- `rules/react/` - React stack constraints
- `rules/vue/` - Vue stack constraints

Rules are copied to projects on `install.py init` (common + stack-specific).

---

## Slash Commands (Flows)

`commands/` ships three orchestration flows, installed to `~/.claude/commands/`:

| Command | Purpose |
|---|---|
| `/flow-new-project` | Full DDD pipeline from idea to deployment (agents 01-25) |
| `/flow-update` | Add a feature / update an existing project (Docker-aware, TDD slices) |
| `/flow-bugfix` | Diagnose and fix a bug with a reproducing test first |

The flows orchestrate the numbered RedWork agents (01-25) plus ambient Claude Code
agents (`code-explorer`, `code-architect`, `planner`, `tdd-guide`, `code-reviewer`,
`security-reviewer`, `build-error-resolver`) and the `plan-critic` agent. They assume
those ambient agents exist in the host Claude Code install.

### plan-critic (adversarial plan gate)

`agents/plan-critic.md` critiques a plan BEFORE implementation, trying to refute it
against the real codebase (missing dependencies, wrong ordering, unverified
assumptions, forgotten migrations/rebuild/rollback). Returns
APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO with concrete evidence. It runs at
the single human gate of `/flow-update` (step 4.5).

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

The flows implement this as **a single human gate** (plan + plan-critic critique),
then continuous execution with automatic gates (tests green, linting, smoke) as the
only advance condition.

---

## Key Commands

| Command | Purpose |
|---|---|
| `python install.py install` | Install framework globally |
| `python install.py init <name>` | Create new project |
| `python install.py update` | Update to latest version |
| `python install.py status` | Show installation info |
| `python scripts/workflow/new_sprint.py N` | Generate sprint N pipeline |
| `python -m pytest tests/ -v` | Run framework tests |

---

## File Structure

```
Framework/
  install.py                    # Global installer
  AGENT_SEQUENCE.md             # Dependency graph
  agents/                       # 25 numbered + auxiliary agents (incl. plan-critic)
  commands/                     # Slash-command flows (flow-new-project, flow-update, flow-bugfix)
  rules/                        # Modular rules (common + stack-specific)
  skills/                       # 14 skill documents
  scripts/
    lib/                        # Python libraries (state, metrics, stack, paths)
    workflow/                   # Validators, auto-commit, sprint generation
    hooks/                      # Git hooks (post-commit v2, post-wave-*)
  stacks/                       # Stack configs (fastapi, django, react, vue)
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

Version: 2.1.0
