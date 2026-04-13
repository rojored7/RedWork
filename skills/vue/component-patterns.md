# Vue Component Patterns

**Version**: 1.0
**Used by**: Agents 15, 16
**Stack**: vue

---

## Single File Component (Composition API)

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

interface Props {
  userId: string
  initialName?: string
}

const props = withDefaults(defineProps<Props>(), {
  initialName: '',
})

const emit = defineEmits<{
  updated: [name: string]
}>()

const name = ref(props.initialName)
const isValid = computed(() => name.value.length > 0)

function handleSubmit() {
  if (isValid.value) {
    emit('updated', name.value)
  }
}
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <input v-model="name" placeholder="Name" />
    <button :disabled="!isValid" type="submit">Save</button>
  </form>
</template>
```

---

## Composables (Custom Hooks)

```typescript
// composables/useUsers.ts
import { ref, readonly } from 'vue'
import type { User } from '@/types'

export function useUsers() {
  const users = ref<User[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchUsers() {
    loading.value = true
    error.value = null
    try {
      const response = await fetch('/api/v1/users')
      users.value = await response.json()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch'
    } finally {
      loading.value = false
    }
  }

  return {
    users: readonly(users),
    loading: readonly(loading),
    error: readonly(error),
    fetchUsers,
  }
}
```

---

## Provide / Inject (Dependency Injection)

```typescript
// Parent component
import { provide } from 'vue'
import { createApiClient } from '@/lib/api'

const apiClient = createApiClient()
provide('apiClient', apiClient)


// Child component (any depth)
import { inject } from 'vue'
import type { ApiClient } from '@/types'

const apiClient = inject<ApiClient>('apiClient')!
```

---

## Slots Pattern

```vue
<!-- BaseCard.vue -->
<template>
  <div class="card">
    <header v-if="$slots.header" class="card-header">
      <slot name="header" />
    </header>
    <div class="card-body">
      <slot />
    </div>
    <footer v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </footer>
  </div>
</template>
```

---

## Anti-Patterns

- Do NOT use Options API in new code (use Composition API with `<script setup>`)
- Do NOT mutate props directly
- Do NOT use `this` in `<script setup>` (it does not exist)
- Do NOT use `v-if` and `v-for` on the same element
- Do NOT overuse watchers (prefer computed properties)
