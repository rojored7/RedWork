# Performance Optimization Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 11 (Frontend Development)
**Purpose**: React performance optimization techniques

---

## Memoization

### useMemo

```typescript
function ExpensiveComponent({ data }: { data: number[] }) {
  // EXPENSIVE computation - only recalculate when data changes
  const sortedData = useMemo(() => {
    console.log('Sorting data...');
    return [...data].sort((a, b) => b - a);
  }, [data]);

  return <div>{sortedData.join(', ')}</div>;
}
```

### useCallback

```typescript
function Parent() {
  const [count, setCount] = useState(0);

  // Stable reference - won't cause Child re-renders
  const handleClick = useCallback(() => {
    setCount(c => c + 1);
  }, []);

  return <Child onClick={handleClick} />;
}

const Child = memo(({ onClick }: { onClick: () => void }) => {
  console.log('Child rendered');
  return <button onClick={onClick}>Click me</button>;
});
```

### React.memo

```typescript
interface UserCardProps {
  user: User;
  onSelect: (user: User) => void;
}

export const UserCard = memo(
  ({ user, onSelect }: UserCardProps) => {
    return (
      <div onClick={() => onSelect(user)}>
        <h3>{user.name}</h3>
        <p>{user.email}</p>
      </div>
    );
  },
  // Custom comparison
  (prevProps, nextProps) => {
    return prevProps.user.id === nextProps.user.id;
  }
);
```

---

## Code Splitting

### Route-based

```typescript
import { lazy, Suspense } from 'react';

const DashboardPage = lazy(() => import('./pages/DashboardPage'));
const ProjectsPage = lazy(() => import('./pages/ProjectsPage'));
const SettingsPage = lazy(() => import('./pages/SettingsPage'));

function App() {
  return (
    <Suspense fallback={<LoadingScreen />}>
      <Routes>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/projects" element={<ProjectsPage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Routes>
    </Suspense>
  );
}
```

### Component-based

```typescript
const HeavyChart = lazy(() => import('./components/HeavyChart'));

function Dashboard() {
  const [showChart, setShowChart] = useState(false);

  return (
    <div>
      <button onClick={() => setShowChart(true)}>Show Chart</button>
      {showChart && (
        <Suspense fallback={<Spinner />}>
          <HeavyChart data={chartData} />
        </Suspense>
      )}
    </div>
  );
}
```

---

## Virtualization

```typescript
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Project[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,
    overscan: 5,
  });

  return (
    <div
      ref={parentRef}
      style={{
        height: '600px',
        overflow: 'auto',
      }}
    >
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            <ProjectCard project={items[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## Image Optimization

### Lazy Loading

```typescript
function LazyImage({ src, alt }: { src: string; alt: string }) {
  const ref = useRef<HTMLImageElement>(null);
  const [isLoaded, setIsLoaded] = useState(false);
  const isVisible = useIntersectionObserver(ref, { threshold: 0.1 });

  return (
    <div ref={ref} style={{ minHeight: '200px', background: '#f0f0f0' }}>
      {isVisible && (
        <img
          src={src}
          alt={alt}
          loading="lazy"
          decoding="async"
          onLoad={() => setIsLoaded(true)}
          style={{ opacity: isLoaded ? 1 : 0, transition: 'opacity 0.3s' }}
        />
      )}
    </div>
  );
}
```

### Responsive Images

```typescript
function ResponsiveImage({ src, alt }: { src: string; alt: string }) {
  return (
    <picture>
      <source
        media="(min-width: 1024px)"
        srcSet={`${src}-large.webp`}
        type="image/webp"
      />
      <source
        media="(min-width: 768px)"
        srcSet={`${src}-medium.webp`}
        type="image/webp"
      />
      <source srcSet={`${src}-small.webp`} type="image/webp" />
      <img src={`${src}.jpg`} alt={alt} loading="lazy" />
    </picture>
  );
}
```

---

## Debounce and Throttle

### useDebounce

```typescript
function SearchBar() {
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearchTerm = useDebounce(searchTerm, 300);

  useEffect(() => {
    if (debouncedSearchTerm) {
      searchAPI(debouncedSearchTerm);
    }
  }, [debouncedSearchTerm]);

  return (
    <input
      value={searchTerm}
      onChange={(e) => setSearchTerm(e.target.value)}
      placeholder="Search..."
    />
  );
}
```

### useThrottle

```typescript
function useThrottle<T>(value: T, interval: number): T {
  const [throttledValue, setThrottledValue] = useState<T>(value);
  const lastExecuted = useRef<number>(Date.now());

  useEffect(() => {
    if (Date.now() >= lastExecuted.current + interval) {
      lastExecuted.current = Date.now();
      setThrottledValue(value);
    } else {
      const timerId = setTimeout(() => {
        lastExecuted.current = Date.now();
        setThrottledValue(value);
      }, interval);

      return () => clearTimeout(timerId);
    }
  }, [value, interval]);

  return throttledValue;
}

// Usage - Scroll event
function ScrollTracker() {
  const [scrollY, setScrollY] = useState(0);
  const throttledScrollY = useThrottle(scrollY, 100);

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return <div>Scroll position: {throttledScrollY}</div>;
}
```

---

## Bundle Size Optimization

### Dynamic Imports

```typescript
async function loadHeavyLibrary() {
  const { heavyFunction } = await import('heavy-library');
  return heavyFunction();
}

function Component() {
  const handleClick = async () => {
    const result = await loadHeavyLibrary();
    console.log(result);
  };

  return <button onClick={handleClick}>Process</button>;
}
```

### Tree Shaking

```typescript
// Import only what you need
import { debounce } from 'lodash-es/debounce'; // ✓ Good
import _ from 'lodash'; // ✗ Bad - imports entire library
```

---

## Web Workers

```typescript
// worker.ts
self.onmessage = (e: MessageEvent<number[]>) => {
  const data = e.data;
  const sorted = data.sort((a, b) => a - b);
  self.postMessage(sorted);
};

// Component
function HeavyComputation({ data }: { data: number[] }) {
  const [result, setResult] = useState<number[]>([]);

  useEffect(() => {
    const worker = new Worker(new URL('./worker.ts', import.meta.url));

    worker.onmessage = (e: MessageEvent<number[]>) => {
      setResult(e.data);
    };

    worker.postMessage(data);

    return () => worker.terminate();
  }, [data]);

  return <div>{result.join(', ')}</div>;
}
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
