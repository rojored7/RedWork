# Deferred — known enterprise debt (conscious, not forgotten)

v2.3 focused the framework on its real objective: the flows working
perfectly end to end as an AI software factory. The following items from
the v2.2 audit are REAL but deliberately deferred. Each one is safe to
defer because the factory currently operates single-user/single-session.

| # | Item | Why it matters | Where the gap lives |
|---|---|---|---|
| 1 | Multi-user locking | Two devs / two Claude sessions doing load->mutate->save on `.project-state/*.json` lose updates; concurrent gates can race on flags | `state_manager.py._save`, `retry_controller.py._save`, `metrics.py._append`, `run-gates.sh` flag section |
| 2 | Versioned `update` with migrations + rollback | `install.py update` re-installs without migrating; no snapshot/rollback; no per-project version pin enforcement | `install.py cmd_update` |
| 3 | Reversible `uninstall` | Uninstall removes `~/.claude/redwork/` but leaves the hooks merged into `~/.claude/settings.json` and the files copied to `~/.claude/hooks|commands|agents` | `install.py cmd_uninstall` (use `install-state.json` to record and revert) |
| 4 | Metrics traceability (schema v2) | metrics.jsonl lacks model / git author / commit SHA / tokens — "which model produced this code" is not answerable | `scripts/lib/metrics.py` |
| 5 | Framework self-coverage gate | Generated projects are gated at 100%; the framework's own test suite has no coverage floor in CI (ratchet plan: `.coverage-floor` that only rises) | `.github/workflows/framework-ci.yml` |
| 6 | Git-history secret scanning | `scan-secrets.sh` covers working tree and staged files, not history; an already-committed secret is invisible | `scripts/security/scan-secrets.sh` (consider gitleaks/trufflehog) |
| 7 | Allow-list bash hook | `pre-bash-validate.sh` is a regex deny-list (evadible by construction) | `.claude/hooks/pre-bash-validate.sh` |
| 8 | Post-release lifecycle agents | No agents for monitoring/SLOs, incident response/rollback, dependency upgrades, or end-user docs | `agents/` (new) |

Source: enterprise audit of v2.2 (session 2026-07-02). When any of these
is picked up, remove its row and reference the implementing commit.
