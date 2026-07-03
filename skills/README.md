# Framework Skills

Centralized reference documents that agents consult instead of duplicating
knowledge inline. After `install.py install` they live at
`~/.claude/redwork/skills/` — that is the path agents reference.

## Layout

```
skills/
  api-dx-design.md              # DX-first API principles (Agent 10)
  configuration-management.md   # Centralized config patterns (Agents 12, 14)
  ddd-clean-architecture.md     # DDD + Clean Architecture (Agents 02, 05, 14)
  openapi-code-generation.md    # OpenAPI 3.0 + codegen (Agents 10, 11, 14, 16)
  security-best-practices.md    # OWASP, secrets, authz (Agents 04b, 14, 21)
  testing-patterns.md           # Unit/integration/E2E patterns (Agents 13, 15, 17, 18)
  fastapi/
    patterns.md                 # Async DDD, DI, SQLAlchemy (Agents 13, 14)
    security.md                 # FastAPI-specific security (Agents 14, 21)
    testing.md                  # pytest + TestClient patterns (Agent 13)
  react/
    accessibility.md            # a11y patterns (Agents 15, 16)
    api-client.md               # Type-safe API clients (Agent 16)
    component-patterns.md       # Component architecture (Agent 16)
    performance.md              # Rendering/bundle performance (Agent 16)
    state-management.md         # Server/client/URL state (Agent 16)
    typescript-quality.md       # TS quality standards (Agents 15, 16)
    ux-design-system.md         # Design system Phase 0 (Agent 16)
  learned/                      # Skills produced by the learning-agent
```

## Rules

- One skill = one authoritative document. No duplicates: the react-specific
  skills live ONLY under `react/` (the flat top-level copies were removed
  in v2.3).
- Agents reference skills by installed path
  (`~/.claude/redwork/skills/<name>.md`); a referenced skill MUST exist —
  `tests/test_reference_integrity.py` enforces it.
- Stack applicability is declared in `stacks/<stack>/config.yaml`
  (`applicable_skills`).
- New skills proposed by the learning loop land in `learned/` and are
  promoted here after human review.
