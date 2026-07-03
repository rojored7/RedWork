# Framework Agents

Agent definitions for the RedWork pipeline. Canonical numbering is v2
(see `AGENT_SEQUENCE.md` at the repo root and `AGENT_DEPENDENCIES` in
`scripts/lib/state_manager.py` — the single source of truth for the graph).

## Pipeline agents (invoked in sequence)

### Prevalidation (always first)
- **impact-prevalidator** (state id `00b`) - Total blast-radius analysis anchored to HEAD; hard gate `validate-impact-analysis.sh`

### Discovery & Design (01-05b)
- **01-product-discovery** - Idea -> structured requirements
- **02-domain-modeling** - Domain model (entities, VOs, aggregates)
- **03-context-mapping** - Bounded contexts (DDD)
- **04-architecture-decision** - Architecture decision (FastAPI backend MANDATORY)
- **04b-security-by-design** - OWASP-compliant security requirements
- **05-service-design** - Service internals (Clean Architecture)
- **05b-technical-design-validator** - Design completeness gate (BLOCKING)

### Planning (06-09)
- **06-epic-generation** - Epics from domain model
- **07-user-story-generation** - Epics -> user stories + BDD
- **08-tech-lead-delivery** - Stories -> technical tasks (with Expected Files)
- **09-sprint-orchestrator** - Tasks -> sprint execution plan

### API Contract (10-11)
- **10-api-specification** - OpenAPI 3.0 spec, DX-first (output `10_api_specification.yaml`)
- **11-implementation-contract** - Binding implementation contract

### Development waves (12-16, orchestrated by 25)
- **12-infrastructure-deployment** - Docker, DB, Redis, networks (Wave 0)
- **13-backend-test** - Backend tests FIRST, TDD Red (Wave 3a)
- **14-backend-development** - Backend implementation, TDD Green (Wave 3b)
- **15-frontend-test** - Frontend tests FIRST, TDD Red (Wave 5a)
- **16-frontend-development** - Frontend implementation, TDD Green (Wave 5b)

### Validation (17-21)
- **17-integration-test** - Backend <-> DB integration
- **18-e2e-test** - End-to-end user flows
- **19-smoke-test** - Critical paths (real execution)
- **20-linting-validator** - 0 errors, 0 warnings (BLOCKING)
- **21-security-review** - Security review (auth, APIs, uploads, secrets)

### Quality (22-24)
- **22-design-compliance** - Design vs implementation compliance
- **23-quick-reference** - Concise CLAUDE.md for the generated project
- **24-build-deploy** - Build & release readiness analysis

### Orchestration
- **25-development-orchestrator** - MANDATORY gateway: Phase 0 activation
  checks (hooks, detection, impact gate) + continuous factory execution

## Auxiliary agents (on demand)

- **project-type-detector** - Detects stack, validates the FastAPI mandate (output `00_project_detection.md`)
- **plan-critic** - Adversarial plan critique at the single human gate
- **configuration-analyzer** - Brownfield configuration analysis (output `06bis_configuration_analysis.md`)
- **hidden-complexity-analyzer** - Non-obvious behaviors in legacy code (output `07bis_hidden_complexity.md`)
- **agent-introspection-debugging** - Structured recovery when an agent fails
- **learning-agent** - Pattern analysis; proposes skills into `skills/learned/`

## Ambient agents (vendored, `ambient/`)

The flows also invoke 9 vendored actors — `code-explorer`, `code-architect`,
`planner`, `tdd-guide`, `code-reviewer`, `security-reviewer`,
`python-reviewer`, `typescript-reviewer`, `build-error-resolver`.
See `ambient/README.md` for provenance and the sync rule.

## Conventions

- Files: `NN-kebab-case.md` (numbered) or `kebab-case.md` (auxiliary/ambient).
- Frontmatter: `name` (kebab-case, unique), `description` (with <example> blocks),
  `model`, optional `tools` and `color`.
- Outputs: `outputs/NN_snake_case.md` — each agent reads its predecessors'
  outputs by this convention.
- Skills live in `~/.claude/redwork/skills/` after install; agents reference
  them by that path.

## Usage

```
"lanza el agente 01-product-discovery quiero un LMS"
```

Or via the flows, which orchestrate everything: `/flow-new-project`,
`/flow-update`, `/flow-bugfix`.

Version history: see `CHANGELOG_v*.md` at the repo root.
