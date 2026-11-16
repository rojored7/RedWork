# Ambient Agents (vendored from ECC)

These 10 agents are the "ambient" actors that the RedWork flows
(`/flow-new-project`, `/flow-update`, `/flow-bugfix`) invoke via the Task
tool. They are vendored here so RedWork is self-contained: installing
RedWork no longer assumes ECC (everything-claude-code) is present on the
host.

| Agent | Role in the flows |
|---|---|
| code-explorer | Fase 1: trace execution paths, map architecture, find pre-existing bugs |
| code-architect | Fase 1: feature blueprint over existing patterns |
| planner | Fase 2: implementation plan (TDD slices) |
| tdd-guide | Slices: RED -> GREEN -> IMPROVE |
| code-reviewer | Review phase (always) |
| security-reviewer | Review phase (auth/input/APIs/payments/crypto) |
| python-reviewer | Review phase (Python changes) |
| typescript-reviewer | Review phase (TS/JS changes) |
| build-error-resolver | Gate failures: fix build/type errors within plan scope |
| doc-updater | /flow-update and /flow-bugfix: sync CLAUDE.md / TECHNICAL_DOCUMENTATION.md per CLAUDE.local.md (vendored 2026-11-16) |

## Provenance and sync rule

- Upstream source of truth: `everything-claude-code/agents/*.md` (ECC).
- Vendored: 2026-07-02, byte-identical copies (no conversion; the
  frontmatter format `name/description/tools/model` is shared).
- Re-sync on every RedWork release: copy the upstream files over these and
  review the diff. Do NOT hand-edit these files in RedWork — fix upstream
  in ECC first, then re-vendor.

## Install behavior

`install.py install` registers these AND the pipeline agents (impact-prevalidator,
01-25, plan-critic...) in `~/.claude/agents/` (the registry the Task tool actually
reads), so every agent a flow names resolves by name. Non-clobbering policy:
- destination missing -> copy (and record in install-state.json)
- destination identical (hash) -> skip (ECC already installed it)
- destination differs -> keep the user's version and warn (never overwrite)
