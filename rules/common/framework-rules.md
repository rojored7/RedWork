---
rule_id: framework-core
applies_to: all
phase: always
enforcement: hook
version: 1.0.0
description: Core framework rules that apply to every RedWork project.
---

# Framework Rules

## 1. No emojis

No emojis in responses, code, comments, commit messages, or documentation.
Enforcement: convention (all agents and skills must comply).

## 2. No personal names in git

Never put personal names in git credentials, commit author fields, or push configurations.
Use generic or team identifiers instead.
Enforcement: convention + pre-bash-validate.sh blocks credential commands.

## 3. FastAPI is default backend

All new projects use FastAPI as the backend framework unless explicitly overridden with `--backend django`.
This is a non-negotiable architectural decision.

Forbidden patterns in backend/:
- `@nestjs`, `express`, `nest-cli.json`
- `pom.xml`, `build.gradle`
- `.ts` files in `backend/`

Enforcement: pre-write-validate.sh + CI pipeline setup stage.
