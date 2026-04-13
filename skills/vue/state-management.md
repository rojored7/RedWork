# Vue State Management (Pinia)

**Version**: 1.0
**Used by**: Agents 15, 16
**Stack**: vue

---

## Store Definition

```typescript
// stores/users.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@/types'

export const useUsersStore = defineStore('users', () => {
  // State
  const users = ref<User[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const activeUsers = computed(() => users.value.filter(u => u.isActive))
  const userCount = computed(() => users.value.length)

  // Actions
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

  function addUser(user: User) {
    users.value = [...users.value, user]
  }

  function removeUser(id: string) {
    users.value = users.value.filter(u => u.id !== id)
  }

  return { users, loading, error, activeUsers, userCount, fetchUsers, addUser, removeUser }
})
```

---

## Store Usage in Component

```vue
<script setup lang="ts">
import { useUsersStore } from '@/stores/users'
import { storeToRefs } from 'pinia'

const store = useUsersStore()

// Use storeToRefs to keep reactivity when destructuring
const { users, loading, error } = storeToRefs(store)

// Actions can be destructured directly (they are functions, not reactive)
const { fetchUsers } = store

onMounted(() => {
  fetchUsers()
})
</script>
```

---

## Store Composition (Store uses Store)

```typescript
export const useCartStore = defineStore('cart', () => {
  const authStore = useAuthStore()
  const items = ref<CartItem[]>([])

  async function checkout() {
    if (!authStore.isAuthenticated) {
      throw new Error('Must be logged in')
    }
    // ... checkout logic
  }

  return { items, checkout }
})
```

---

## Server State vs Client State

| Concern | Tool |
|---------|------|
| Server data (users, products) | VueQuery / TanStack Query |
| Client UI state (modals, theme) | Pinia |
| URL state (filters, pagination) | Vue Router query params |
| Form state | VeeValidate or local refs |

---

## Anti-Patterns

- Do NOT put everything in a single store (split by domain)
- Do NOT mutate store state from components (use actions)
- Do NOT use `storeToRefs` for actions (only for reactive state/getters)
- Do NOT duplicate server state in Pinia (use TanStack Query for cache)
