---
rule_id: security-enforcement
applies_to: all
phase: always
enforcement: hook
version: 1.0.0
description: Security rules enforced across all RedWork projects.
---

# Security Rules

## 1. No hardcoded secrets

Never hardcode API keys, passwords, tokens, or connection strings in source code.
Use environment variables or a secrets manager.

Enforcement: pre-write-validate.sh blocks writes containing secret patterns.
Enforcement: scan-secrets.sh runs in post-wave hooks and CI pipeline.

## 2. No .env files in git

`.env`, `.env.production`, `.env.local` must be in `.gitignore`.
Enforcement: post-wave hooks check `git ls-files` for .env files.

## 3. JWT and auth secrets from environment only

```python
# Correct
SECRET_KEY = os.environ["JWT_SECRET_KEY"]

# Forbidden
SECRET_KEY = "my-hardcoded-secret-key"
```

## 4. Password hashing requirements

- Use bcrypt with minimum 12 rounds
- Never store plaintext passwords
- Never log passwords or tokens

## 5. Rate limiting required

All public API endpoints must have rate limiting configured.

## 6. No debug output in production

- No `print()` statements in production Python code (use `logging` module)
- No `console.log()` in production frontend code
- No `DEBUG = True` in production configuration

## 7. Input validation at boundaries

Validate all external input (API requests, file uploads, query parameters)
using Pydantic models (backend) or schema validation (frontend).

## 8. Error messages must not leak internals

API error responses must use generic messages. Stack traces and internal paths
must never reach the client. Log detailed errors server-side only.
