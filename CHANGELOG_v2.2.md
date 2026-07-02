# RedWork Framework v2.2.0

Theme: **impact pre-validation + development factory**. A hard-gated
impact analysis now anchors every flow, and execution runs end to end
with bounded automatic retries — one human gate, then work until the
result (or an honest escalation).

## Added

### `agents/impact-prevalidator.md` — total-impact pre-validator (new)
Runs FIRST in every flow, before exploring or planning. Maps against the
real repo: blast radius (inverse dependencies), data layer / pending
migrations, Docker services (COPY vs volume), API contracts, and the test
baseline (pre-existing red vs introduced red). Emits
`outputs/00b_impact_analysis.md` anchored to `git rev-parse HEAD` with a
`VERDE / AMARILLO / ROJO` verdict. Registered in `state_manager.py` as
agent `00b` (agents 01 and 25 depend on it) and in the
`update-workflow-status.sh` scanner.

### `scripts/workflow/validate-impact-analysis.sh` — hard gate (new)
```
Exit: 0 = fresh VERDE (or AMARILLO with --allow-amber)
      1 = ROJO (or AMARILLO without the flag)
      2 = report missing   3 = malformed   4 = stale (HEAD moved)
```
Wired as Agent 25 Phase 0 **check 0.6** (banner now shows six checks) and
as the Fase 2 precondition of the three flows.

### Factory loop machinery (new)
- `scripts/lib/retry_controller.py`: persistent per-gate retry state
  (`.project-state/retry_state.json`), `FRAMEWORK_MAX_RETRIES` cap
  (default 3), metrics integration, and `get_next_action()` →
  `run_agent | retry_gate | escalate_human | done`. CLI for bash.
- `scripts/workflow/run-gates.sh <wave>`: THE single re-runnable wave
  gate (post-wave hook + completeness). Exit 0 clears
  `wave_N_blocked.flag` automatically (previously nothing ever cleared
  it), 1 = retry available, 2 = exhausted → `needs_human.flag`.
- `post-commit-workflow` delegates wave validation to `run-gates.sh`, so
  the git hook and manual retries share one gate and one counter.
- `session-start.sh` surfaces `NEEDS HUMAN` and active retry counts.
- `resume-development.sh` emits a machine-readable `NEXT_ACTION`.

### `.gitattributes` (new)
`*.sh` / `*.py` / extensionless hooks forced to LF. Windows checkouts
with `core.autocrlf=true` used to CRLF-corrupt every bash script (67
tests failing locally); this closes that class of breakage permanently.

## Changed

### Single-gate doctrine enforced in the .md layer
- **Agent 25**: removed `Phase 4: User Approval Gate` ("Type 'proceed'"),
  which contradicted the Execution Doctrine. New
  `Phase 4: Continuous Factory Execution` documents the loop:
  next action → run agent / fix-within-scope + re-run gate / escalate
  with a consolidated report (attempts, evidence, options) / done.
- **flow-new-project**: 3 human gates collapsed into ONE decision package
  (impact verdict + domain + architecture + sprint plan + plan-critic).
- **flow-update / flow-bugfix**: new Fase 0 (impact-prevalidator); the
  single human gate now includes the impact verdict; bounded retries
  documented.

### Portability (Windows Git Bash) fixes
- New `scripts/lib/python-detect.sh` (`$PYTHON_BIN`: python3 → python →
  py launcher, each candidate verified by executing code). Adopted by 17
  bash scripts that hardcoded `python3` — on Windows the enforcement
  hooks were silently allowing everything (empty vars → exit 0).
- `on-stop.sh`: portable mtime (GNU stat → BSD stat → Python).
- `tests/conftest.py`: Git usr/bin prepended to PATH for subprocess bash.

### Broken references closed
- `install.py` generated projects pointed SessionStart at a nonexistent
  `session-start-project.sh` → now `~/.claude/hooks/session-start.sh`.
- `validate-agent-*.sh` looked for outputs at the repo root while agents
  write to `outputs/` → outputs/ first, root as legacy fallback.
- `resume-development.sh` mapped backend/frontend to v1 agent numbers
  (10/11/14) → canonical v2 (14/16/15).
- `new_sprint.py` interactive `input()` hung non-interactive runs →
  `--force` flag + isatty detection.
- CI banner/child pipeline still referenced renamed agents 05c/09b → 10/11.

## Tests
393 → **427 total (416 passing + 11 skipped, 0 failing)**: +13 impact
gate, +17 retry controller/run-gates, +2 manifest-filter regression, +2
graph asserts. Full suite green on Windows for the first time (v2.1 had
67 failures locally from CRLF + python3 breakage).

## Fixed
- `install.py _copy_dir`: profile manifests (backend-only/frontend-only)
  matched ZERO files (compared src-relative names against repo-relative
  entries) — profile installs silently copied no agents/skills at all.
  Now matches `agents/<file>` with normalized separators.

## Migration notes
- Re-run `python install.py install` to refresh `~/.claude/redwork/`
  (global copies lack run-gates.sh / retry_controller.py / the 00b agent).
- Existing v2.1 projects: the next `get_next_agent()` will return `00b`
  — run the impact-prevalidator once to anchor the pipeline before
  continuing.
