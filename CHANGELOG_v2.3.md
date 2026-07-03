# RedWork Framework v2.3.0 — "The factory"

Theme: **flows first, git in the background**. The objective of this
release is single: `/flow-new-project`, `/flow-update` and `/flow-bugfix`
work perfectly end to end as an AI software factory, with quality gates
the FLOWS invoke directly and 100% acceptance everywhere.

## Breaking

- **The commit-driven engine is gone.** Gates no longer depend on
  `[TASK-SN-XX-NNN]` commit messages or the post-commit hook (now opt-in
  via `REDWORK_COMMIT_HOOKS=1`). The flows run the gates synchronously.
- **Auto-push eliminated.** `checkpoint-commit.sh` never pushes;
  `auto-commit-task.sh` (deprecated) pushes only with `REDWORK_AUTO_PUSH=1`.
  Publishing is always a human decision.
- **Django and Vue scaffolding removed** (FastAPI + React only): stacks/,
  rules/, skills/ pruned; `install.py init` rejects other stacks.
- **GitLab child-pipeline theater removed** (`.gitlab/ci/` deleted — the
  2h file-polling jobs, sprint templates and the deploy TODO stub).
  `.gitlab-ci.yml` is now a 38-line honest mirror. Canonical CI is GitHub
  Actions. `install-pipeline.sh` / `pipeline-helper.sh` deleted;
  `new_sprint.py` no longer generates CI YAML.
- **Deploy declared out of scope** (`docs/DEPLOYMENT.md` in every project)
  instead of shipping a stub.
- **Agent 22 CONDITIONAL band removed**: compliance verdict is binary
  (APPROVED == 100% / REJECTED).

## Added

- **`agents/ambient/`** — the 9 flow actors vendored from ECC
  (code-explorer, code-architect, planner, tdd-guide, code-reviewer,
  security-reviewer, python-reviewer, typescript-reviewer,
  build-error-resolver). `install.py` installs them to `~/.claude/agents/`
  with a non-clobbering hash policy. ECC is no longer a prerequisite.
- **`scripts/workflow/slice-gate.sh`** — per-slice gate: ruff + mypy +
  `pytest --cov=app --cov-fail-under=100` / eslint + tsc + `vitest run
  --coverage` (thresholds 100). Missing coverage tooling = FAIL, never a
  silent skip. Green writes the checkpoint authorization marker.
- **`scripts/workflow/checkpoint-commit.sh`** — silent checkpoint: only
  after a fresh green gate, selective staging with defensive excludes,
  BLOCKING staged secret scan, quiet commit, never empty, never pushed.
- **100% coverage as a real gate** in post-wave hooks, `enforce-100.sh`,
  slice-gate and project CI; project templates
  (`templates/project/backend-pyproject.toml`, `frontend-vitest.config.ts`)
  carry the thresholds with a reviewed, entrypoint-only omit contract.
- **`.github/workflows/framework-ci.yml`** — canonical CI: pytest suite,
  bash syntax check of every script, FastAPI mandate, secret+config scan,
  reference-integrity sweep. Zero `continue-on-error`.
- **Projects get GitHub Actions CI** with the SAME gate commands as the
  local gates (one contract), plus `scripts/security/` copied locally and
  `.project-state/` gitignored (no state merge conflicts).
- **`scripts/maintenance/sweep_references.py`** — mechanical reference
  sweeps with `--check` mode (runs in CI and tests).
- **`scripts/lib/version.py`** — single source of version truth;
  `state.json.framework_version` now stamps the real version (the
  "2.0.0" hardcode is gone).
- **`docs/DEFERRED.md`** — conscious enterprise debt, itemized.
- Tests: 436 passing + 11 skipped. New: test_ambient_agents (invocation
  integrity — THE factory test), test_reference_integrity (drift guards +
  flow gate contracts), test_factory_gates, test_factory_flow (full chain
  E2E), test_ci_pipeline (rewritten). Live smoke evidence in
  `docs/scratch/factory-smoke-v2.3.md`.

## Fixed (content drift that broke the flows)

- `framework/skills/` phantom path (19 refs) -> real installed path.
- `~/.config/claude/PROTOCOL.md` phantom prerequisite removed (agent 14).
- v1->v2 agent numbering swept everywhere (README said "Agent 10" builds
  the backend — that is API Specification in v2).
- Agent 13 rewritten: pure TDD-Red (audit Frankenstein removed), output
  filename collision fixed.
- Agent 10: ONE API standard (page/pageSize, `sort=-createdAt`, no
  brackets, errors with `suggestion`) — it previously mandated two
  incompatible contracts.
- Agent 01: motivational filler pruned; open questions now ACCUMULATE to
  the single human gate instead of contradicting the no-questions rule.
- 7 byte-identical duplicate skills removed (canonical `skills/react/`).
- `agents/workflow-orchestrator/` (~2,500 dead Node lines from another
  project) deleted; learning loop redirected to `skills/learned/`.
- Agent frontmatter names normalized (name == filename, kebab-case,
  unique); wsl-docker-orchestrator name collision resolved by removal.
- `scan-secrets.sh --staged`: no longer scans its own pattern files nor
  `.md` docs (parity with directory mode) — both found live by the smoke.

## Migration notes

- Re-run `python install.py install --profile full` (installs ambient
  agents, new gates, templates).
- Existing projects: add `.project-state/` to .gitignore, copy the
  coverage templates, and replace any `[TASK-]`-based habits with
  `slice-gate.sh` + `checkpoint-commit.sh`.
- If you relied on auto-push: export `REDWORK_AUTO_PUSH=1` (not
  recommended — push deliberately).
