# State Management Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 11 (Frontend Development)
**Purpose**: React state management strategies

---

## Context + Reducer Pattern

```typescript
// types.ts
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: CartItem }
  | { type: 'REMOVE_ITEM'; payload: { id: string } }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'CLEAR_CART' };

// reducer.ts
function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existingItem = state.items.find(item => item.id === action.payload.id);

      if (existingItem) {
        return {
          ...state,
          items: state.items.map(item =>
            item.id === action.payload.id
              ? { ...item, quantity: item.quantity + action.payload.quantity }
              : item
          ),
          total: state.total + action.payload.price * action.payload.quantity,
        };
      }

      return {
        ...state,
        items: [...state.items, action.payload],
        total: state.total + action.payload.price * action.payload.quantity,
      };
    }

    case 'REMOVE_ITEM': {
      const item = state.items.find(i => i.id === action.payload.id);
      if (!item) return state;

      return {
        ...state,
        items: state.items.filter(i => i.id !== action.payload.id),
        total: state.total - item.price * item.quantity,
      };
    }

    case 'UPDATE_QUANTITY': {
      const item = state.items.find(i => i.id === action.payload.id);
      if (!item) return state;

      const quantityDiff = action.payload.quantity - item.quantity;

      return {
        ...state,
        items: state.items.map(i =>
          i.id === action.payload.id
            ? { ...i, quantity: action.payload.quantity }
            : i
        ),
        total: state.total + item.price * quantityDiff,
      };
    }

    case 'CLEAR_CART':
      return { items: [], total: 0 };

    default:
      return state;
  }
}

// CartContext.tsx
interface CartContextValue {
  state: CartState;
  dispatch: React.Dispatch<CartAction>;
}

const CartContext = createContext<CartContextValue | null>(null);

export function CartProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [], total: 0 });

  return (
    <CartContext.Provider value={{ state, dispatch }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) throw new Error('useCart must be used within CartProvider');
  return context;
}

// Usage in component
function AddToCartButton({ product }: { product: Product }) {
  const { dispatch } = useCart();

  return (
    <button
      onClick={() =>
        dispatch({
          type: 'ADD_ITEM',
          payload: {
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
          },
        })
      }
    >
      Add to Cart
    </button>
  );
}
```

---

## Zustand Global State

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  updateProfile: (data: Partial<User>) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,

      login: async (email, password) => {
        const response = await fetch('/api/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password }),
        });

        if (!response.ok) throw new Error('Login failed');

        const { user, token } = await response.json();
        set({ user, token });
      },

      logout: () => {
        set({ user: null, token: null });
      },

      updateProfile: (data) => {
        const currentUser = get().user;
        if (!currentUser) return;

        set({ user: { ...currentUser, ...data } });
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ user: state.user, token: state.token }),
    }
  )
);

// Usage
function LoginForm() {
  const login = useAuthStore(state => state.login);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await login(email, password);
  };

  return <form onSubmit={handleSubmit}>...</form>;
}

function UserProfile() {
  const user = useAuthStore(state => state.user);
  const updateProfile = useAuthStore(state => state.updateProfile);

  if (!user) return <Redirect to="/login" />;

  return <ProfileForm user={user} onSave={updateProfile} />;
}
```

---

## React Query Server State

```typescript
// hooks/useProjects.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

interface Project {
  id: string;
  name: string;
  description: string;
}

export function useProjects() {
  return useQuery({
    queryKey: ['projects'],
    queryFn: async () => {
      const response = await fetch('/api/projects');
      if (!response.ok) throw new Error('Failed to fetch projects');
      return response.json() as Promise<Project[]>;
    },
  });
}

export function useProject(id: string) {
  return useQuery({
    queryKey: ['projects', id],
    queryFn: async () => {
      const response = await fetch(`/api/projects/${id}`);
      if (!response.ok) throw new Error('Failed to fetch project');
      return response.json() as Promise<Project>;
    },
    enabled: !!id,
  });
}

export function useCreateProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: Omit<Project, 'id'>) => {
      const response = await fetch('/api/projects', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });

      if (!response.ok) throw new Error('Failed to create project');
      return response.json() as Promise<Project>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    },
  });
}

export function useUpdateProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...data }: Partial<Project> & { id: string }) => {
      const response = await fetch(`/api/projects/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });

      if (!response.ok) throw new Error('Failed to update project');
      return response.json() as Promise<Project>;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
      queryClient.invalidateQueries({ queryKey: ['projects', variables.id] });
    },
  });
}

export function useDeleteProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const response = await fetch(`/api/projects/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) throw new Error('Failed to delete project');
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    },
  });
}

// Usage in component
function ProjectList() {
  const { data: projects, isLoading, error } = useProjects();
  const deleteProject = useDeleteProject();

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} />;

  return (
    <ul>
      {projects?.map(project => (
        <li key={project.id}>
          {project.name}
          <button onClick={() => deleteProject.mutate(project.id)}>
            Delete
          </button>
        </li>
      ))}
    </ul>
  );
}

function CreateProjectForm() {
  const createProject = useCreateProject();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    await createProject.mutateAsync({
      name: projectName,
      description: projectDescription,
    });
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

---

## State Colocation

**Principle**: Keep state as close as possible to where it's used.

```typescript
// BAD - Global state for local concern
const useGlobalStore = create((set) => ({
  modalOpen: false,
  setModalOpen: (open: boolean) => set({ modalOpen: open }),
}));

function Component() {
  const { modalOpen, setModalOpen } = useGlobalStore();
  return <Modal open={modalOpen} onClose={() => setModalOpen(false)} />;
}

// GOOD - Local state for local concern
function Component() {
  const [modalOpen, setModalOpen] = useState(false);
  return <Modal open={modalOpen} onClose={() => setModalOpen(false)} />;
}

// GOOD - Lift state only when needed
function Parent() {
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  return (
    <>
      <UserList onSelectUser={setSelectedUser} />
      <UserDetails user={selectedUser} />
    </>
  );
}
```

---

## Optimistic Updates

```typescript
function useOptimisticUpdate() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (updatedProject: Project) => {
      const response = await fetch(`/api/projects/${updatedProject.id}`, {
        method: 'PUT',
        body: JSON.stringify(updatedProject),
      });
      return response.json();
    },
    onMutate: async (updatedProject) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['projects', updatedProject.id] });

      // Snapshot previous value
      const previousProject = queryClient.getQueryData(['projects', updatedProject.id]);

      // Optimistically update
      queryClient.setQueryData(['projects', updatedProject.id], updatedProject);

      // Return context with snapshot
      return { previousProject };
    },
    onError: (err, updatedProject, context) => {
      // Rollback on error
      if (context?.previousProject) {
        queryClient.setQueryData(
          ['projects', updatedProject.id],
          context.previousProject
        );
      }
    },
    onSettled: (updatedProject) => {
      // Refetch after error or success
      queryClient.invalidateQueries({ queryKey: ['projects', updatedProject.id] });
    },
  });
}
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
**Maintainer**: Framework Team
