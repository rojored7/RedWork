# CLAUDE.md - RedWork Framework v2.0

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
  agents/                       # 25 numbered + 5 auxiliary agents
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

Version: 2.0.0
