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

## Pydantic v2 Conventions

- All request/response models use Pydantic v2 `BaseModel`
- Use `model_config = ConfigDict(frozen=True)` for immutable DTOs
- Use `Field(...)` with descriptions for API documentation
- Prefer `Annotated[str, Field(...)]` over `name: str = Field(...)`

## Async Patterns

- All endpoint functions must be `async def`
- Use `asyncio.gather()` for parallel I/O operations
- Never use `time.sleep()` in async code (use `asyncio.sleep()`)

## Dependency Injection

- Use `Depends()` for all service dependencies
- Define dependencies as functions, not classes
- Repository and service instances via DI, never direct instantiation in endpoints

## Health Check

Every project must expose `GET /health` returning `{"status": "ok"}`.
This is used by smoke-test.sh and CI pipeline health validation.

## CI Configuration

- Image: `python:3.12-slim`
- Project file: `pyproject.toml`
- Build: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
