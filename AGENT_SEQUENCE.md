# RedWork Agent Sequence

## Execution Flow

```
DISCOVERY (manual, sequential):
  01-product-discovery
  02-domain-modeling
  03-context-mapping
  04-architecture-decision
    04b-security-by-design (optional gate)
  05-service-design
    05b-technical-design-validator (optional gate)

PLANNING (manual, sequential):
  06-epic-generation
  07-user-story-generation
  08-tech-lead-delivery
  09-sprint-orchestrator

API CONTRACT (manual, after planning):
  10-api-specification
  11-implementation-contract

DEVELOPMENT (orchestrated by Agent 25):
  12-infrastructure-deployment (Wave 0, once per group)
  |
  +-- 13-backend-test (Wave 3a, TDD Red)      <-- parallel
  |   14-backend-development (Wave 3b, TDD Green)
  |
  +-- 15-frontend-test (Wave 5a, TDD Red)      <-- parallel
      16-frontend-development (Wave 5b, TDD Green)

VALIDATION (orchestrated by Agent 25):
  17-integration-test
  18-e2e-test
  19-smoke-test
  20-linting-validator
  21-security-review

QUALITY (orchestrated by Agent 25):
  22-design-compliance
  23-quick-reference
  24-build-deploy

ORCHESTRATOR:
  25-development-orchestrator (manages waves 0-5 + validation + quality)
```

## Dependency Graph

```
01 --> 02 --> 03 --> 04 --> 05 --> 06 --> 07 --> 08 --> 09 --> 10 --> 11
                      |                                         |
                      04b                                       12
                      |                                        / \
                      05b                                     /   \
                                                            13    15
                                                            |     |
                                                            14    16
                                                             \   /
                                                              17
                                                              |
                                                           18-19-20
                                                              |
                                                              21
                                                              |
                                                           22-23-24
```

## Auxiliary Agents (no fixed number, invoked on demand)

- project-type-detector: Detects project type and validates stack
- configuration-analyzer: Analyzes existing configs in brownfield projects
- hidden-complexity-analyzer: Discovers non-obvious behaviors in legacy code
- agent-introspection-debugging: Debugs failing agents
- learning-agent: Analyzes patterns and proposes new skills

## TDD Wave Order

| Wave | Agent | Role | Phase |
|------|-------|------|-------|
| 0 | 12 | Infrastructure setup | Setup |
| 3a | 13 | Backend tests from specs | Red (all fail) |
| 3b | 14 | Backend implementation | Green (make pass) |
| 5a | 15 | Frontend tests from specs | Red (all fail) |
| 5b | 16 | Frontend implementation | Green (make pass) |
| V | 17-21 | Integration, E2E, smoke, lint, security | Validation |
| Q | 22-24 | Compliance, reference, deploy analysis | Quality |

Waves 3a and 5a run in PARALLEL (no dependency between them).
Waves 3b and 5b run in PARALLEL (each depends only on its own 'a' wave).
Validation waits for BOTH 3b and 5b to complete.
