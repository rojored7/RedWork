---
rule_id: stack-django
applies_to: django
phase: development
enforcement: hook
version: 1.0.0
description: Django-specific stack rules and constraints.
---

# Django Stack Rules

## Language

Python only in `backend/`. No TypeScript, Java, or other languages.

## Framework Constraints

- Use Django with Django REST Framework for APIs
- Use `python -m pytest tests/ -v` for testing
- Use `ruff` for linting, `mypy` for type checking
- Source directory: `.` (Django convention)
- Test directory: `tests/`

## Forbidden Patterns

These patterns are blocked by pre-write-validate.sh:

- `@nestjs` - NestJS imports
- `express` - Express.js imports
- `nest-cli.json` - NestJS config files

## CI Configuration

- Image: `python:3.12-slim`
- Project file: `pyproject.toml`
- Build: `python manage.py runserver 0.0.0.0:8000`
