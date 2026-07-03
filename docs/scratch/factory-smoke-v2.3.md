# Factory smoke — v2.3 (2026-07-02)

Mechanical end-to-end smoke of the factory engine on a REAL generated
project (`install.py init demo-factory`, temp workspace). Windows 11 +
Git Bash + py 3.14.

## What was exercised (live, not mocked)

| Step | Result |
|---|---|
| `install.py init demo-factory` | Structure OK: `.github/workflows/ci.yml`, NO `.gitlab*`, `backend/pyproject.toml` (fail_under=100), `frontend/vitest.config.ts` (thresholds 100), `scripts/security/` copied, `.gitignore` excludes `.project-state/`, `state.json.framework_version == 2.3.0` |
| `slice-gate.sh backend` (mini app + test) | REAL pytest-cov run: "Required test coverage of 100% reached. Total coverage: 100.00%" -> exit 0, marker written |
| Coverage broken (untested function added) | `slice-gate.sh` exit 1, "pytest/coverage below 100%", no new marker |
| Secret staged (`AKIA...` in cfg.py) | `checkpoint-commit.sh` BLOCKED with file:line, nothing committed |
| `checkpoint-commit.sh` after green gate | Silent commit `checkpoint: S1-BE-001 — calc.add con test al 100%`, exit 0, NO push (script contains no push path) |
| `run-gates.sh 3` on incomplete demo | Honest FAIL, "attempt 1 3, retry available" — retry counter live in `.project-state/retry_state.json` |

## Bugs found BY the smoke and fixed in the same pass

1. `scan-secrets.sh --staged` scanned the scanner's own pattern files
   (copied into projects since v2.3) -> guaranteed false positives.
   Fixed: pattern files excluded in staged mode.
2. Staged mode scanned `.md` files while directory mode never did; rules
   docs teach with anti-example snippets ("my-hardcoded-secret-key") and
   were blocking checkpoints. Fixed: parity (.md excluded in staged mode).
3. Demo repos without git identity made checkpoint fail with exit 3
   (infrastructure) — correct signal, documented here: configure
   user.email/user.name per project or globally.

## Not covered by this smoke (needs a real flow session)

- The 9 ambient agents resolving live via the Task tool (guaranteed
  statically by tests/test_ambient_agents.py + installed copies).
- The single human gate presentation (impact + plan + plan-critic).
- Recommendation: first real use of `/flow-update` on a small feature IS
  the remaining acceptance test; run it on a real project and update this
  file with the result.
