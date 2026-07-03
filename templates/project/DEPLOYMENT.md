# Deployment

**RedWork does not manage deployment.** This is an honest, explicit scope
boundary — not a TODO.

What the framework DOES guarantee before anything ships:
- Sprint completeness 100% (every planned task implemented, verified
  against the repo tree)
- Test suites green with 100% code coverage (hard gates, not advisory)
- Zero lint errors, security review, smoke tests on critical paths
- Agent 24 (build & release readiness) analyzes the build artifacts and
  flags release risks

What YOU own:
- Where and how this project deploys (hosting, orchestration, secrets,
  environments, rollback strategy)
- The decision to push/publish (RedWork checkpoints are always local;
  nothing is pushed automatically)

If you add deployment automation (GitHub Actions deploy job, Terraform,
etc.), keep it in your project — and keep the RedWork gates as its
preconditions.
