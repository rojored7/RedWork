---
rule_id: tdd-mandatory
applies_to: all
phase: development
enforcement: ci
version: 1.0.0
description: TDD is mandatory - tests before implementation.
---

# TDD Rules

## Test-First Mandate

Tests MUST be written BEFORE implementation code.

Agent execution order enforces this:
- Agent 13 (backend tests) runs BEFORE Agent 14 (backend implementation)
- Agent 15 (frontend tests) runs BEFORE Agent 16 (frontend implementation)

## Workflow

1. Write test (RED) - test must fail
2. Run test - confirm failure
3. Write minimal implementation (GREEN)
4. Run test - confirm pass
5. Refactor (IMPROVE)
6. Verify coverage >= 80%

## Coverage Requirement

Minimum 80% test coverage for all modules.

## Test Types Required

1. Unit tests - individual functions, utilities, components
2. Integration tests - API endpoints, database operations
3. E2E tests - critical user flows

Enforcement: CI pipeline validates coverage. Agent 25 blocks waves if tests not written first.
