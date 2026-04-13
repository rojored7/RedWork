---
rule_id: stack-vue
applies_to: vue
phase: development
enforcement: convention
version: 1.0.0
description: Vue-specific stack rules and constraints.
---

# Vue Stack Rules

## Language

TypeScript in `frontend/`.

## Framework Constraints

- Use Vue 3 with Composition API
- Use Vitest for testing
- Use ESLint for linting, `vue-tsc` for type checking
- Source directory: `src/`
- Test directory: `src/__tests__/`

## Conventions

- Single File Components (SFC) with `<script setup lang="ts">`
- Composables with `use` prefix
- State management: Pinia
- No Options API in new code

## CI Configuration

- Image: `node:20-slim`
- Project file: `package.json`
- Build: `npm run build`
