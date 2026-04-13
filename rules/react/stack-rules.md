---
rule_id: stack-react
applies_to: react
phase: development
enforcement: convention
version: 1.0.0
description: React-specific stack rules and constraints.
---

# React Stack Rules

## Language

TypeScript in `frontend/`.

## Framework Constraints

- Use React with functional components and hooks
- Use Vitest for testing
- Use ESLint for linting, `tsc` for type checking
- Source directory: `src/`
- Test directory: `src/__tests__/`

## Conventions

- Components in PascalCase
- Hooks with `use` prefix
- State management: prefer React Query for server state, Zustand/Jotai for client state
- No class components

## CI Configuration

- Image: `node:20-slim`
- Project file: `package.json`
- Build: `npm run build`
