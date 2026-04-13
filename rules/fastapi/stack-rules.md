---
rule_id: stack-fastapi
applies_to: fastapi
phase: development
enforcement: hook
version: 1.0.0
description: FastAPI-specific stack rules and constraints.
---

# FastAPI Stack Rules

## Language

Python only in `backend/`. No TypeScript, Java, or other languages.

## Framework Constraints

- Use FastAPI with Pydantic v2 for request/response models
- Use `python -m pytest tests/ -v` for testing
- Use `ruff` for linting, `mypy` for type checking
- Source directory: `app/`
- Test directory: `tests/`

## Forbidden Patterns

These patterns are blocked by pre-write-validate.sh:

- `@nestjs` - NestJS imports
- `express` - Express.js imports
- `nest-cli.json` - NestJS config files
- `pom.xml` - Maven/Java build files
- `build.gradle` - Gradle/Java build files
- `.ts` files in `backend/` - TypeScript in Python backend

## CI Configuration

- Image: `python:3.12-slim`
- Project file: `pyproject.toml`
- Build: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
