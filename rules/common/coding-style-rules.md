---
rule_id: coding-style
applies_to: all
phase: development
enforcement: convention
version: 1.0.0
description: Coding style rules for consistency across RedWork projects.
---

# Coding Style Rules

## 1. Immutable data structures preferred

Use frozen dataclasses, NamedTuple, or Pydantic models with `frozen=True`
for domain entities and value objects.

```python
@dataclass(frozen=True)
class UserId:
    value: str
```

## 2. Single responsibility per file

Each file should have one primary class or closely related set of functions.
Target 200-400 lines. Maximum 800 lines per file.

## 3. Factory methods for complex construction

Entities with validation logic should use factory methods or class methods
instead of exposing `__init__` directly.

## 4. Naming conventions

- Python: `snake_case` for functions/variables, `PascalCase` for classes
- TypeScript: `camelCase` for functions/variables, `PascalCase` for types/components
- Constants: `UPPER_SNAKE_CASE` in both languages
- Booleans: `is_`, `has_`, `should_`, `can_` prefixes

## 5. No deep nesting

Maximum 4 levels of indentation. Use early returns and guard clauses.

## 6. Explicit error handling

Handle errors at every level. Never silently swallow exceptions.
Use Result types or explicit try/except with specific exception types.

## 7. No magic numbers

Use named constants for thresholds, delays, limits, and configuration values.
