# RedWork Framework v2.1.0

Additive release: orchestration flows + adversarial plan gate + execution doctrine.
No breaking changes to the 01-25 agent sequence.

## Added

### `commands/` — slash-command flows (new)
Three orchestration flows, installed to `~/.claude/commands/` by `install.py`:

- **`/flow-new-project`** — full DDD pipeline (agents 01-25) from idea to deployment.
  Human gates only for product decisions (domain, architecture, sprint plan); each
  sprint then runs end to end.
- **`/flow-update`** — add a feature / update an existing project. Docker-aware
  (rebuild + migration sequence), plan decomposed into TDD slices (1 slice = 1 commit),
  single human gate (plan + plan-critic critique), then continuous execution with
  automatic gates.
- **`/flow-bugfix`** — diagnose + fix with a reproducing test first; the test ships in
  the same commit as the fix.

### `agents/plan-critic.md` — adversarial plan critic (new)
Runs BEFORE implementation and tries to refute the plan against the real codebase
(missing dependencies, wrong ordering, unverified assumptions, forgotten
migrations/rebuild/rollback, scope creep). Returns
`APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO` with concrete evidence
(file paths, grep results). Wired as the single human gate of `/flow-update` (step 4.5).

### Execution Doctrine (CLAUDE.md)
Approved plan = full authorization to execute end to end. Flows collapse the old
multi-checkpoint model into a **single human gate**, with automatic gates
(tests green, linting, smoke) as the only advance condition. One consolidated report
at the end.

## Changed

- `install.py`: `VERSION` → 2.1.0; new step copies `commands/*.md` to
  `~/.claude/commands/` during `install` / `update`.
- `CLAUDE.md`: documents `commands/`, `plan-critic`, and the Execution Doctrine;
  file-structure section updated.

## Notes

- The flows orchestrate the numbered RedWork agents (01-25) **plus** ambient Claude Code
  agents (`code-explorer`, `code-architect`, `planner`, `tdd-guide`, `code-reviewer`,
  `security-reviewer`, `build-error-resolver`). They assume those ambient agents exist
  in the host Claude Code install.
- Agent references inside the flows were mapped to the canonical v2 numbering
  (e.g. backend impl → `14-backend-development`, smoke → `19-smoke-test`,
  security → `21-security-review`).
