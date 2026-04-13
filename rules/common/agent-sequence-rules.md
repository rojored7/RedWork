---
rule_id: agent-sequence
applies_to: all
phase: always
enforcement: hook
version: 1.0.0
description: Agent execution sequence and dependency rules.
---

# Agent Sequence Rules

## Agent 25 Phase 0

Agent 25 (Development Orchestrator) Phase 0 MUST run before any development wave.
Phase 0 activates hooks, validates prerequisites, and manages wave execution.

## Dependency Graph

```
DISCOVERY:  01 -> 02 -> 03 -> 04 [-> 04b] -> 05 [-> 05b]
PLANNING:   06 -> 07 -> 08 -> 09
API:        10 -> 11
ORCHESTR:   25 (Phase 0 activates hooks, then manages waves)
INFRA:      12
BACKEND:    13 (tests first) -> 14 (implementation)
FRONTEND:   15 (tests first) -> 16 (implementation)
VALIDATION: 17 -> 18 -> 19 -> 20 -> 21
QUALITY:    22 -> 23 -> 24
```

## Parallel Waves

Waves 3a (backend tests) and 5a (frontend tests) can run in PARALLEL.
All other sequences are strictly sequential within their phase.

## State Tracking

Agent progress is tracked in `.project-state/state.json`.
Each agent reads its predecessors' outputs from `outputs/` and generates its own.

Enforcement: session-start.sh injects state context. user-prompt-classify.sh warns on missing prerequisites.
