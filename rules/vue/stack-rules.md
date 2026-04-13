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

## Composition API Required

All new components must use `<script setup lang="ts">`.
Options API is forbidden in new code.

## Pinia Store Naming

- Store files: `use{Entity}Store.ts` (e.g., `useUserStore.ts`)
- Store IDs match filename: `defineStore('user', ...)`
- Actions handle async operations, getters for derived state

## Emit Type Declarations

All component emits must be typed:
```vue
const emit = defineEmits<{
  update: [value: string]
  delete: [id: number]
}>()
```

## CI Configuration

- Image: `node:20-slim`
- Project file: `package.json`
- Build: `npm run build`
