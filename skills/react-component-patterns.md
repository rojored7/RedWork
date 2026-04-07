# React Component Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 11 (Frontend Development)
**Purpose**: Reusable React component architecture patterns

---

## Compound Components Pattern

**When to use**: When components work together as a family with shared state.

```typescript
// Select.tsx
interface SelectContextValue {
  value: string;
  onChange: (value: string) => void;
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
}

const SelectContext = createContext<SelectContextValue | null>(null);

export function Select({
  value,
  onChange,
  children
}: {
  value: string;
  onChange: (value: string) => void;
  children: React.ReactNode;
}) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <SelectContext.Provider value={{ value, onChange, isOpen, setIsOpen }}>
      <div className="select">{children}</div>
    </SelectContext.Provider>
  );
}

Select.Trigger = function SelectTrigger({ children }: { children: React.ReactNode }) {
  const context = useContext(SelectContext);
  if (!context) throw new Error('SelectTrigger must be used within Select');

  return (
    <button onClick={() => context.setIsOpen(!context.isOpen)}>
      {children}
    </button>
  );
};

Select.Options = function SelectOptions({ children }: { children: React.ReactNode }) {
  const context = useContext(SelectContext);
  if (!context) throw new Error('SelectOptions must be used within Select');
  if (!context.isOpen) return null;

  return <div className="options">{children}</div>;
};

Select.Option = function SelectOption({
  value,
  children
}: {
  value: string;
  children: React.ReactNode;
}) {
  const context = useContext(SelectContext);
  if (!context) throw new Error('SelectOption must be used within Select');

  return (
    <div
      onClick={() => {
        context.onChange(value);
        context.setIsOpen(false);
      }}
    >
      {children}
    </div>
  );
};

// Usage
<Select value={selected} onChange={setSelected}>
  <Select.Trigger>Choose option</Select.Trigger>
  <Select.Options>
    <Select.Option value="1">Option 1</Select.Option>
    <Select.Option value="2">Option 2</Select.Option>
  </Select.Options>
</Select>
```

---

## Render Props Pattern

**When to use**: When logic needs to be reused but UI varies.

```typescript
interface DataFetcherProps<T> {
  url: string;
  children: (data: {
    data: T | null;
    loading: boolean;
    error: Error | null;
    refetch: () => void;
  }) => React.ReactNode;
}

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch(url);
      const json = await response.json();
      setData(json);
      setError(null);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return <>{children({ data, loading, error, refetch: fetchData })}</>;
}

// Usage
<DataFetcher<User[]> url="/api/users">
  {({ data, loading, error, refetch }) => {
    if (loading) return <Spinner />;
    if (error) return <Error message={error.message} retry={refetch} />;
    return <UserList users={data} />;
  }}
</DataFetcher>
```

---

## Custom Hooks

### useForm Hook

```typescript
interface UseFormOptions<T> {
  initialValues: T;
  onSubmit: (values: T) => void | Promise<void>;
  validate?: (values: T) => Partial<Record<keyof T, string>>;
}

function useForm<T extends Record<string, any>>({
  initialValues,
  onSubmit,
  validate,
}: UseFormOptions<T>) {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleChange = (name: keyof T) => (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    setValues(prev => ({ ...prev, [name]: e.target.value }));
  };

  const handleBlur = (name: keyof T) => () => {
    setTouched(prev => ({ ...prev, [name]: true }));
    if (validate) {
      const validationErrors = validate(values);
      setErrors(validationErrors);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (validate) {
      const validationErrors = validate(values);
      setErrors(validationErrors);
      if (Object.keys(validationErrors).length > 0) return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit(values);
    } finally {
      setIsSubmitting(false);
    }
  };

  return {
    values,
    errors,
    touched,
    isSubmitting,
    handleChange,
    handleBlur,
    handleSubmit,
  };
}

// Usage
const { values, errors, handleChange, handleBlur, handleSubmit } = useForm({
  initialValues: { email: '', password: '' },
  validate: (values) => {
    const errors: any = {};
    if (!values.email) errors.email = 'Required';
    if (!values.password) errors.password = 'Required';
    return errors;
  },
  onSubmit: async (values) => {
    await login(values);
  },
});
```

### useDebounce Hook

```typescript
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage
const [searchTerm, setSearchTerm] = useState('');
const debouncedSearchTerm = useDebounce(searchTerm, 300);

useEffect(() => {
  if (debouncedSearchTerm) {
    searchAPI(debouncedSearchTerm);
  }
}, [debouncedSearchTerm]);
```

### useLocalStorage Hook

```typescript
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue] as const;
}

// Usage
const [theme, setTheme] = useLocalStorage('theme', 'light');
```

### useIntersectionObserver Hook

```typescript
function useIntersectionObserver(
  ref: RefObject<Element>,
  options?: IntersectionObserverInit
): boolean {
  const [isIntersecting, setIsIntersecting] = useState(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const observer = new IntersectionObserver(([entry]) => {
      setIsIntersecting(entry.isIntersecting);
    }, options);

    observer.observe(element);

    return () => {
      observer.unobserve(element);
    };
  }, [ref, options]);

  return isIntersecting;
}

// Usage - Lazy loading images
const ref = useRef<HTMLDivElement>(null);
const isVisible = useIntersectionObserver(ref, { threshold: 0.1 });

return (
  <div ref={ref}>
    {isVisible && <img src={imageSrc} alt="Lazy loaded" />}
  </div>
);
```

---

## Higher-Order Components (HOCs)

### withAuth HOC

```typescript
function withAuth<P extends object>(
  Component: React.ComponentType<P>
): React.FC<P> {
  return function AuthenticatedComponent(props: P) {
    const { user, loading } = useAuth();
    const navigate = useNavigate();

    useEffect(() => {
      if (!loading && !user) {
        navigate('/login');
      }
    }, [user, loading, navigate]);

    if (loading) return <Spinner />;
    if (!user) return null;

    return <Component {...props} />;
  };
}

// Usage
const ProtectedDashboard = withAuth(Dashboard);
```

### withErrorBoundary HOC

```typescript
function withErrorBoundary<P extends object>(
  Component: React.ComponentType<P>,
  FallbackComponent: React.ComponentType<{ error: Error; resetError: () => void }>
): React.ComponentType<P> {
  return class extends React.Component<P, { hasError: boolean; error: Error | null }> {
    state = { hasError: false, error: null };

    static getDerivedStateFromError(error: Error) {
      return { hasError: true, error };
    }

    resetError = () => {
      this.setState({ hasError: false, error: null });
    };

    render() {
      if (this.state.hasError && this.state.error) {
        return <FallbackComponent error={this.state.error} resetError={this.resetError} />;
      }

      return <Component {...this.props} />;
    }
  };
}

// Usage
const SafeUserList = withErrorBoundary(UserList, ErrorFallback);
```

---

## Component Composition Strategies

### Container/Presenter Pattern

```typescript
// Presenter - Pure UI component
interface UserListPresenterProps {
  users: User[];
  loading: boolean;
  error: Error | null;
  onUserClick: (user: User) => void;
}

function UserListPresenter({
  users,
  loading,
  error,
  onUserClick
}: UserListPresenterProps) {
  if (loading) return <Spinner />;
  if (error) return <Error message={error.message} />;

  return (
    <ul>
      {users.map(user => (
        <li key={user.id} onClick={() => onUserClick(user)}>
          {user.name}
        </li>
      ))}
    </ul>
  );
}

// Container - Logic + data fetching
function UserListContainer() {
  const { data: users, loading, error } = useUsers();
  const navigate = useNavigate();

  const handleUserClick = (user: User) => {
    navigate(`/users/${user.id}`);
  };

  return (
    <UserListPresenter
      users={users ?? []}
      loading={loading}
      error={error}
      onUserClick={handleUserClick}
    />
  );
}
```

### Slots Pattern

```typescript
interface CardProps {
  header?: React.ReactNode;
  body: React.ReactNode;
  footer?: React.ReactNode;
}

function Card({ header, body, footer }: CardProps) {
  return (
    <div className="card">
      {header && <div className="card-header">{header}</div>}
      <div className="card-body">{body}</div>
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
}

// Usage
<Card
  header={<h2>User Profile</h2>}
  body={<UserProfile user={user} />}
  footer={<Button>Edit</Button>}
/>
```

---

## Advanced Patterns

### Controlled vs Uncontrolled Components

```typescript
// Controlled Component
function ControlledInput() {
  const [value, setValue] = useState('');

  return (
    <input
      value={value}
      onChange={(e) => setValue(e.target.value)}
    />
  );
}

// Uncontrolled Component
function UncontrolledInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = () => {
    console.log(inputRef.current?.value);
  };

  return <input ref={inputRef} />;
}
```

### Polymorphic Component Pattern

```typescript
type PolymorphicProps<E extends React.ElementType> = {
  as?: E;
  children: React.ReactNode;
} & React.ComponentPropsWithoutRef<E>;

function Text<E extends React.ElementType = 'span'>({
  as,
  children,
  ...props
}: PolymorphicProps<E>) {
  const Component = as || 'span';
  return <Component {...props}>{children}</Component>;
}

// Usage
<Text>Default span</Text>
<Text as="h1">Heading</Text>
<Text as="p">Paragraph</Text>
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
**Maintainer**: Framework Team
