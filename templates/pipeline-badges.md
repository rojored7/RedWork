# Pipeline Status Badges

Add these badges to your project README.md for visual pipeline status.
Replace `PROJECT_PATH` with your GitLab project path (e.g., `rojored7/gaia`).

---

## Main Pipeline Status

```markdown
[![Pipeline Status](https://gitlab.com/PROJECT_PATH/badges/main/pipeline.svg)](https://gitlab.com/PROJECT_PATH/-/pipelines)
```

## Coverage (if configured)

```markdown
[![Coverage](https://gitlab.com/PROJECT_PATH/badges/main/coverage.svg)](https://gitlab.com/PROJECT_PATH/-/pipelines)
```

---

## Custom Shields.io Badges (Agent Phases)

These badges are HARDCODED colors. They do NOT reflect live status, but they
give the visual color distinction you asked for per agent phase.

```markdown
## Workflow Status

### Discovery Phase
![Agent 01](https://img.shields.io/badge/01-Product_Discovery-red)
![Agent 02](https://img.shields.io/badge/02-Domain_Modeling-orange)
![Agent 03](https://img.shields.io/badge/03-Context_Mapping-yellow)
![Agent 04](https://img.shields.io/badge/04-Architecture_Decision-yellowgreen)
![Agent 04b](https://img.shields.io/badge/04b-Security_by_Design-darkred)
![Agent 05](https://img.shields.io/badge/05-Service_Design-green)
![Agent 05b](https://img.shields.io/badge/05b-Design_Validator-brightgreen)

### Planning Phase
![Agent 06](https://img.shields.io/badge/06-Epic_Generation-blue)
![Agent 07](https://img.shields.io/badge/07-User_Stories-blueviolet)
![Agent 08](https://img.shields.io/badge/08-Tech_Lead-purple)
![Agent 09](https://img.shields.io/badge/09-Sprint_Plan-ff69b4)

### API Contract Phase
![Agent 05c](https://img.shields.io/badge/05c-OpenAPI_Spec-informational)
![Agent 09b](https://img.shields.io/badge/09b-Implementation_Contract-critical)

### Infrastructure Phase
![Agent 12](https://img.shields.io/badge/12-Docker_K8s-2496ED)

### Sprint Development (Waves)
![Wave 1](https://img.shields.io/badge/Wave_1-Domain_Layer-success)
![Wave 2](https://img.shields.io/badge/Wave_2-Application-success)
![Wave 3](https://img.shields.io/badge/Wave_3-API_Layer-important)
![Wave 4](https://img.shields.io/badge/Wave_4-Frontend-blue)
![Wave 5](https://img.shields.io/badge/Wave_5-Quality-blueviolet)

### Quality Gates
![Agent 19](https://img.shields.io/badge/19-Security_Review-red)
![Agent 20](https://img.shields.io/badge/20-Linting-yellow)

### Deployment
![Staging](https://img.shields.io/badge/Deploy-Staging-blue)
![Production](https://img.shields.io/badge/Deploy-Production-darkgreen)
```

---

## Dynamic Badges (reflect LIVE pipeline status)

These badges use GitLab's custom badge API and DO update based on real
pipeline runs (but require each job to set a badge via API).

```markdown
![Agent 01](https://gitlab.com/PROJECT_PATH/-/jobs/artifacts/main/raw/badges/agent-01.svg?job=01:+product-discovery)
```

---

## Example: Put at top of your README.md

```markdown
# MyProject

[![Pipeline](https://gitlab.com/PROJECT_PATH/badges/main/pipeline.svg)](https://gitlab.com/PROJECT_PATH/-/pipelines)
![Framework](https://img.shields.io/badge/framework-v3.0-blueviolet)
![Backend](https://img.shields.io/badge/backend-FastAPI-009688)
![Frontend](https://img.shields.io/badge/frontend-React_18-61DAFB)

## Workflow Phases

| Phase | Status |
|-------|--------|
| Discovery | ![](https://img.shields.io/badge/phase_1-Discovery-red) |
| Planning | ![](https://img.shields.io/badge/phase_2-Planning-orange) |
| API Contract | ![](https://img.shields.io/badge/phase_3-API_Contract-yellow) |
| Infrastructure | ![](https://img.shields.io/badge/phase_4-Infrastructure-green) |
| Sprint 1 | ![](https://img.shields.io/badge/phase_5-Sprint_1-blue) |
| Quality | ![](https://img.shields.io/badge/phase_6-Quality-blueviolet) |
| Deploy | ![](https://img.shields.io/badge/phase_7-Deploy-darkgreen) |
```
