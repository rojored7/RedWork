# Quality Enforcement Framework - Roadmap

This document outlines future enhancements for the 4-layer quality enforcement framework.

---

## Current Status (2026-03-31)

### ✅ Implemented Layers

| Layer | Status | Description |
|-------|--------|-------------|
| **Layer 1** | ✅ COMPLETE | Agent-level enforcement via `.claude/AUTOMATIC_HOOK_ENFORCEMENT.md` |
| **Layer 2** | ✅ COMPLETE | Git hooks (pre-commit, pre-push) via `scripts/install-git-hooks.sh` |
| **Layer 3** | 📋 ROADMAP | CI/CD validation via GitHub Actions (this document) |
| **Layer 4** | ✅ COMPLETE | Documentation via `CLAUDE.md` and framework docs |

### Why Layer 3 is Needed

**Layers 1 and 2 work for local development**, but they can be bypassed:
- Layer 1: Agent can skip hooks if not enforced
- Layer 2: Developer can use `git commit --no-verify` or `git push --no-verify`

**Layer 3 (CI/CD) is the LAST LINE OF DEFENSE:**
- Runs automatically on every PR
- Cannot be bypassed (enforced by GitHub branch protection)
- Validates code quality before merge to main/production
- Provides team-wide visibility of test results

---

## Layer 3: CI/CD Implementation Plan

### Overview

Create GitHub Actions workflows that validate:
1. **PR Quality Gate** - Runs on every pull request
2. **Sprint Baseline Gate** - Validates sprint completion before merge
3. **Deployment Gate** - Ensures production-ready code

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Developer pushes to feature branch                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions: PR Validation Workflow                     │
│  Jobs:                                                       │
│    1. Backend Validation                                     │
│       → npm run build (0 errors)                             │
│       → npm run lint (0 errors, 0 warnings)                  │
│       → npm test (100% passing)                              │
│       → npm run test:integration (100% passing)              │
│    2. Frontend Validation                                    │
│       → npm run type-check (0 errors)                        │
│       → npm run build (0 errors)                             │
│       → npm run lint (0 errors, 0 warnings)                  │
│       → npm test (100% passing)                              │
│    3. E2E Tests                                              │
│       → npx playwright test (100% passing)                   │
│    4. Coverage Report                                        │
│       → Generate coverage report                             │
│       → Enforce 100% coverage threshold                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  GitHub: Check Status on PR                                 │
│  ❌ BLOCKED - Cannot merge until all checks pass            │
│  ✅ PASSED - Ready to merge                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Roadmap Items

### Phase 1: Basic PR Validation (Priority: HIGH)

**Goal**: Prevent broken code from being merged

**Deliverable**: `.github/workflows/pr-validation.yml`

**Features**:
- ✅ Backend compilation validation
- ✅ Backend linting validation
- ✅ Backend unit tests (100% passing required)
- ✅ Frontend type checking
- ✅ Frontend build validation
- ✅ Frontend linting validation
- ✅ Frontend unit tests (100% passing required)

**Workflow Triggers**:
```yaml
on:
  pull_request:
    branches: [main, develop, sprint-*]
  push:
    branches: [main, develop]
```

**Success Criteria**:
- All jobs must pass (compilation, linting, tests)
- Tests: 100% passing (0 failures)
- Linting: 0 errors, 0 warnings
- PR cannot be merged if ANY job fails

**Implementation Steps**:
1. Create `.github/workflows/pr-validation.yml`
2. Configure Docker services (PostgreSQL, Redis) for tests
3. Set up test caching for faster execution
4. Configure branch protection rules on GitHub
5. Test workflow with sample PR

**Estimated Effort**: 4-6 hours

---

### Phase 2: Integration Tests in CI (Priority: HIGH)

**Goal**: Validate cross-layer integration in CI environment

**Deliverable**: Add integration test job to `pr-validation.yml`

**Features**:
- ✅ Run backend integration tests with real PostgreSQL
- ✅ Run backend integration tests with real Redis
- ✅ Validate database schema migrations
- ✅ Validate API contracts

**New Job**:
```yaml
integration-tests:
  runs-on: ubuntu-latest
  services:
    postgres:
      image: postgres:15
      env:
        POSTGRES_PASSWORD: test
        POSTGRES_DB: taskmanager_test
    redis:
      image: redis:7
  steps:
    - name: Run integration tests
      run: npm run test:integration
    - name: Validate 100% passing
      run: |
        if grep -q "failing" test-output.txt; then
          exit 1
        fi
```

**Success Criteria**:
- Integration tests run in isolated environment
- Tests connect to real database/Redis (not mocks)
- 100% integration tests passing
- Test execution time < 3 minutes

**Implementation Steps**:
1. Add `integration-tests` job to workflow
2. Configure GitHub Services (postgres, redis)
3. Set up test database seeding
4. Configure environment variables for tests
5. Test workflow with integration tests

**Estimated Effort**: 2-4 hours

---

### Phase 3: E2E Tests in CI (Priority: MEDIUM)

**Goal**: Validate full user flows in CI environment

**Deliverable**: Add E2E test job to `pr-validation.yml`

**Features**:
- ✅ Run Playwright E2E tests
- ✅ Start backend + frontend in CI
- ✅ Capture screenshots on failure
- ✅ Generate E2E test report

**New Job**:
```yaml
e2e-tests:
  runs-on: ubuntu-latest
  services:
    postgres:
      image: postgres:15
    redis:
      image: redis:7
  steps:
    - name: Start backend
      run: npm run backend &
    - name: Start frontend
      run: npm run frontend &
    - name: Run E2E tests
      run: npx playwright test
    - name: Upload artifacts
      if: failure()
      uses: actions/upload-artifact@v3
      with:
        name: playwright-screenshots
        path: test-results/
```

**Success Criteria**:
- E2E tests run against live backend + frontend
- Tests: 100% passing
- Screenshots captured on failure
- Test execution time < 5 minutes

**Implementation Steps**:
1. Add `e2e-tests` job to workflow
2. Configure backend/frontend startup in CI
3. Wait for services to be ready (health checks)
4. Run Playwright tests
5. Upload artifacts on failure

**Estimated Effort**: 4-6 hours

---

### Phase 4: Coverage Enforcement (Priority: MEDIUM)

**Goal**: Enforce 100% test coverage in CI

**Deliverable**: Add coverage job to `pr-validation.yml`

**Features**:
- ✅ Generate coverage reports for backend
- ✅ Generate coverage reports for frontend
- ✅ Enforce 100% coverage threshold
- ✅ Block PR if coverage < 100%
- ✅ Post coverage comment on PR

**New Job**:
```yaml
coverage:
  runs-on: ubuntu-latest
  steps:
    - name: Backend coverage
      run: |
        cd backend
        npm test -- --coverage
    - name: Check backend coverage
      run: |
        COVERAGE=$(cat backend/coverage/coverage-summary.json | jq '.total.lines.pct')
        if [ "$COVERAGE" != "100" ]; then
          echo "❌ Backend coverage: $COVERAGE% (required: 100%)"
          exit 1
        fi
    - name: Frontend coverage
      run: |
        cd frontend
        npm run test:coverage
    - name: Check frontend coverage
      run: |
        COVERAGE=$(cat frontend/coverage/coverage-summary.json | jq '.total.lines.pct')
        if [ "$COVERAGE" != "100" ]; then
          echo "❌ Frontend coverage: $COVERAGE% (required: 100%)"
          exit 1
        fi
    - name: Comment PR
      uses: actions/github-script@v6
      with:
        script: |
          const coverage = { backend: 100, frontend: 100 };
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            body: `✅ Coverage: Backend ${coverage.backend}%, Frontend ${coverage.frontend}%`
          });
```

**Success Criteria**:
- Coverage reports generated for backend + frontend
- PR blocked if coverage < 100%
- Coverage stats posted as PR comment
- Team has visibility of coverage trends

**Implementation Steps**:
1. Add `coverage` job to workflow
2. Configure coverage thresholds in jest/vitest
3. Parse coverage reports (coverage-summary.json)
4. Add GitHub Script to comment on PR
5. Test with PR that has < 100% coverage

**Estimated Effort**: 3-5 hours

---

### Phase 5: Sprint Baseline Validation (Priority: LOW)

**Goal**: Validate sprint completion before merging to main

**Deliverable**: `.github/workflows/sprint-baseline.yml`

**Features**:
- ✅ Run full sprint baseline validation
- ✅ Validate all gates (compilation, tests, coverage, linting)
- ✅ Generate sprint completion report
- ✅ Block merge if baseline not met

**Workflow Triggers**:
```yaml
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, labeled]
```

**New Workflow**:
```yaml
name: Sprint Baseline Validation

jobs:
  baseline:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.labels.*.name, 'sprint-complete')
    steps:
      - name: Detect sprint number
        run: |
          BRANCH="${{ github.head_ref }}"
          if [[ $BRANCH =~ sprint-([0-9]+) ]]; then
            echo "SPRINT_NUMBER=${BASH_REMATCH[1]}" >> $GITHUB_ENV
          else
            echo "SPRINT_NUMBER=current" >> $GITHUB_ENV
          fi
      - name: Run sprint baseline
        run: bash scripts/enforce-sprint-baseline.sh $SPRINT_NUMBER
      - name: Upload report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: sprint-baseline-report
          path: .project-orchestration/sprint-*-baseline-report-*.md
```

**Success Criteria**:
- Baseline validation runs when PR labeled "sprint-complete"
- All sprint gates pass (100% tests, 100% coverage, 0 linting)
- Sprint report generated and uploaded
- PR blocked if baseline fails

**Implementation Steps**:
1. Create `.github/workflows/sprint-baseline.yml`
2. Configure label-based triggers
3. Integrate with existing `scripts/enforce-sprint-baseline.sh`
4. Upload baseline report as artifact
5. Test with sprint PR

**Estimated Effort**: 2-3 hours

---

### Phase 6: Deployment Gate (Priority: LOW)

**Goal**: Ensure only production-ready code is deployed

**Deliverable**: `.github/workflows/deploy-validation.yml`

**Features**:
- ✅ Run smoke tests before deployment
- ✅ Validate environment variables
- ✅ Check database migration status
- ✅ Verify infrastructure health

**Workflow Triggers**:
```yaml
on:
  push:
    branches: [main]
    tags: ['v*']
```

**New Workflow**:
```yaml
name: Deployment Validation

jobs:
  pre-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Run smoke tests
        run: bash scripts/validate-smoke-tests.sh
      - name: Check migrations
        run: npm run typeorm migration:show
      - name: Validate environment
        run: bash scripts/validate-env.sh
```

**Success Criteria**:
- Smoke tests pass before deployment
- Database migrations up to date
- Environment validated
- Deployment blocked if ANY check fails

**Implementation Steps**:
1. Create `.github/workflows/deploy-validation.yml`
2. Create smoke test validation script
3. Create environment validation script
4. Test workflow with deployment trigger

**Estimated Effort**: 3-4 hours

---

## Implementation Timeline

### Week 1: Foundation
- [ ] Phase 1: Basic PR Validation (4-6 hours)
- [ ] Phase 2: Integration Tests in CI (2-4 hours)
- [ ] Configure branch protection rules on GitHub

### Week 2: Coverage + E2E
- [ ] Phase 3: E2E Tests in CI (4-6 hours)
- [ ] Phase 4: Coverage Enforcement (3-5 hours)

### Week 3: Sprint + Deployment
- [ ] Phase 5: Sprint Baseline Validation (2-3 hours)
- [ ] Phase 6: Deployment Gate (3-4 hours)

**Total Estimated Effort**: 18-28 hours (2.5-3.5 weeks)

---

## Branch Protection Configuration

Once Layer 3 (CI/CD) is implemented, configure GitHub branch protection:

### Main Branch Protection

```
Settings → Branches → Add rule

Branch name pattern: main

Rules:
✅ Require pull request before merging
✅ Require status checks to pass before merging
   → backend-validation
   → frontend-validation
   → integration-tests
   → e2e-tests
   → coverage
✅ Require branches to be up to date before merging
✅ Do not allow bypassing the above settings
✅ Restrict who can push to matching branches (admins only)
```

### Sprint Branch Protection

```
Branch name pattern: sprint-*

Rules:
✅ Require pull request before merging
✅ Require status checks to pass before merging
   → backend-validation
   → frontend-validation
✅ Allow force pushes (for sprint work)
```

---

## Cost Considerations

### GitHub Actions Minutes (Free Tier)

- **Free tier**: 2,000 minutes/month for private repos
- **Estimated usage per PR**:
  - PR validation: ~5-10 minutes
  - Integration tests: ~3-5 minutes
  - E2E tests: ~5-10 minutes
  - **Total per PR**: ~15-25 minutes

- **For a team of 5 developers**:
  - 10 PRs/week × 25 minutes = 250 minutes/week
  - 1,000 minutes/month
  - **Within free tier limits**

### Optimizations

1. **Caching**: Cache node_modules to reduce installation time
2. **Parallel Jobs**: Run backend/frontend validation in parallel
3. **Conditional Execution**: Skip E2E if only docs changed
4. **Matrix Strategy**: Test multiple Node.js versions in parallel

---

## Future Enhancements (Beyond Layer 3)

### Automated Reporting Dashboard
- Visual sprint progress tracking
- Coverage trends over time
- Test execution time trends
- Code quality metrics (complexity, duplication)

### Performance Testing
- Lighthouse CI for frontend performance
- Backend API response time validation
- Database query performance tracking

### Security Scanning
- Snyk for dependency vulnerabilities
- SonarQube for code quality + security
- OWASP ZAP for security testing

### Deployment Automation
- Automatic deployment to staging on PR merge
- Blue-green deployment strategy
- Rollback automation on failure

---

## Success Metrics

### Layer 3 Success Criteria

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **PRs blocked** | 0 broken PRs merged to main | GitHub branch protection logs |
| **Test coverage** | 100% on all modules | Coverage reports in CI |
| **CI execution time** | < 10 minutes per PR | GitHub Actions logs |
| **Developer experience** | No false positives | Team feedback |
| **Deployment confidence** | 0 production incidents due to bad code | Production monitoring |

---

## Rollout Plan

### Phase 1: Pilot (Week 1)
- Implement PR validation only
- Test with 1-2 developers
- Collect feedback
- Fix issues

### Phase 2: Team (Week 2-3)
- Roll out to entire team
- Add integration + E2E tests
- Enable branch protection
- Monitor CI execution time

### Phase 3: Production (Week 4)
- Add sprint baseline validation
- Add deployment gate
- Enforce 100% coverage
- Full rollout complete

---

## Support and Maintenance

### Who Maintains Layer 3?
- **DevOps Lead**: GitHub Actions configuration
- **Tech Lead**: Branch protection rules, quality gates
- **Team**: Contribute improvements to workflows

### How to Update Workflows?
1. Create branch: `ci/improve-workflow`
2. Edit workflows in `.github/workflows/`
3. Test changes with PR
4. Merge to main after validation

### How to Disable Layer 3 (Emergency)?
```bash
# Temporarily disable branch protection (GitHub Settings → Branches)
# OR bypass with admin override (not recommended)
```

---

**Created**: 2026-03-31
**Version**: 1.0.0 (Roadmap for Layer 3 implementation)
**Status**: Planning Phase
**Next Action**: Implement Phase 1 (Basic PR Validation)
