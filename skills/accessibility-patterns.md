# Accessibility Patterns (WCAG AA)

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 11 (Frontend Development)
**Purpose**: WCAG AA accessibility patterns

---

## Semantic HTML

```typescript
// BAD - divs for everything
<div onClick={handleClick}>Submit</div>

// GOOD - semantic elements
<button onClick={handleClick}>Submit</button>

// BAD - divs for navigation
<div className="nav">
  <div onClick={goHome}>Home</div>
</div>

// GOOD - nav with semantic elements
<nav>
  <a href="/">Home</a>
</nav>
```

---

## ARIA Labels and Roles

```typescript
// Icon-only button
function IconButton({ onClick, icon, label }: IconButtonProps) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      type="button"
    >
      {icon}
    </button>
  );
}

// Form with aria-describedby
function EmailInput() {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');

  return (
    <div>
      <label htmlFor="email">Email</label>
      <input
        id="email"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        aria-describedby={error ? 'email-error' : undefined}
        aria-invalid={!!error}
      />
      {error && (
        <div id="email-error" role="alert">
          {error}
        </div>
      )}
    </div>
  );
}

// Live region for dynamic content
function Notifications() {
  const [message, setMessage] = useState('');

  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      {message}
    </div>
  );
}
```

---

## Keyboard Navigation

```typescript
function Dropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const listRef = useRef<HTMLUListElement>(null);

  const handleKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
    switch (e.key) {
      case 'Enter':
      case ' ':
        e.preventDefault();
        setIsOpen(!isOpen);
        break;
      case 'Escape':
        setIsOpen(false);
        buttonRef.current?.focus();
        break;
      case 'ArrowDown':
        e.preventDefault();
        if (!isOpen) {
          setIsOpen(true);
        } else {
          setSelectedIndex(i => Math.min(i + 1, options.length - 1));
        }
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex(i => Math.max(i - 1, 0));
        break;
    }
  };

  return (
    <div>
      <button
        ref={buttonRef}
        onClick={() => setIsOpen(!isOpen)}
        onKeyDown={handleKeyDown}
        aria-haspopup="listbox"
        aria-expanded={isOpen}
      >
        Select option
      </button>
      {isOpen && (
        <ul
          ref={listRef}
          role="listbox"
          aria-activedescendant={`option-${selectedIndex}`}
        >
          {options.map((option, index) => (
            <li
              key={option.id}
              id={`option-${index}`}
              role="option"
              aria-selected={index === selectedIndex}
              onClick={() => handleSelect(option)}
            >
              {option.label}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

---

## Focus Management

```typescript
function Modal({ isOpen, onClose, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      // Save current focus
      previousFocusRef.current = document.activeElement as HTMLElement;

      // Focus modal
      modalRef.current?.focus();
    } else {
      // Restore focus
      previousFocusRef.current?.focus();
    }
  }, [isOpen]);

  // Trap focus inside modal
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Tab') {
      const focusableElements = modalRef.current?.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );

      if (!focusableElements) return;

      const firstElement = focusableElements[0] as HTMLElement;
      const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

      if (e.shiftKey && document.activeElement === firstElement) {
        e.preventDefault();
        lastElement.focus();
      } else if (!e.shiftKey && document.activeElement === lastElement) {
        e.preventDefault();
        firstElement.focus();
      }
    } else if (e.key === 'Escape') {
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div
      ref={modalRef}
      className="modal"
      role="dialog"
      aria-modal="true"
      tabIndex={-1}
      onKeyDown={handleKeyDown}
    >
      {children}
    </div>
  );
}

// Skip to main content link
function SkipLink() {
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only"
      style={{
        position: 'absolute',
        left: '-9999px',
        '&:focus': {
          position: 'static',
        },
      }}
    >
      Skip to main content
    </a>
  );
}
```

---

## Screen Reader Support

```typescript
// Visually hidden but accessible
const srOnly = {
  position: 'absolute',
  width: '1px',
  height: '1px',
  padding: 0,
  margin: '-1px',
  overflow: 'hidden',
  clip: 'rect(0, 0, 0, 0)',
  whiteSpace: 'nowrap',
  borderWidth: 0,
} as const;

function DataTable({ data }: { data: User[] }) {
  return (
    <table>
      <thead>
        <tr>
          <th scope="col">Name</th>
          <th scope="col">Email</th>
          <th scope="col">
            Actions
            <span style={srOnly}>for user</span>
          </th>
        </tr>
      </thead>
      <tbody>
        {data.map(user => (
          <tr key={user.id}>
            <td>{user.name}</td>
            <td>{user.email}</td>
            <td>
              <button aria-label={`Edit ${user.name}`}>
                <EditIcon />
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// Loading state announcement
function LoadingData() {
  return (
    <div>
      <div aria-live="polite" aria-busy="true">
        Loading data...
      </div>
      <Spinner aria-hidden="true" />
    </div>
  );
}
```

---

## Color Contrast

```typescript
// Design tokens with WCAG AA compliance
export const colors = {
  // Normal text: 4.5:1 minimum
  text: {
    primary: '#1a1a1a',     // 16:1 on white
    secondary: '#4a4a4a',   // 9.7:1 on white
    tertiary: '#6a6a6a',    // 5.7:1 on white
  },

  // Large text (18px+ or 14px+ bold): 3:1 minimum
  heading: {
    primary: '#2a2a2a',     // 13.5:1 on white
  },

  // UI components: 3:1 minimum
  border: {
    default: '#9a9a9a',     // 3.5:1 on white
    focus: '#0066cc',       // 7.7:1 on white
  },

  // Backgrounds
  background: {
    primary: '#ffffff',
    secondary: '#f5f5f5',
  },
};

// Usage
<div style={{ color: colors.text.primary, background: colors.background.primary }}>
  High contrast text (16:1 ratio)
</div>
```

---

## Form Accessibility

```typescript
function AccessibleForm() {
  return (
    <form>
      {/* Label association */}
      <div>
        <label htmlFor="username">Username</label>
        <input
          id="username"
          type="text"
          required
          aria-required="true"
        />
      </div>

      {/* Fieldset for related inputs */}
      <fieldset>
        <legend>Contact Information</legend>
        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            aria-describedby="email-help"
          />
          <div id="email-help">We'll never share your email</div>
        </div>
      </fieldset>

      {/* Error messages */}
      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          aria-invalid={hasError}
          aria-describedby={hasError ? 'password-error' : undefined}
        />
        {hasError && (
          <div id="password-error" role="alert">
            Password must be at least 8 characters
          </div>
        )}
      </div>

      {/* Submit button */}
      <button type="submit">
        Submit
        <span style={srOnly}>registration form</span>
      </button>
    </form>
  );
}
```

---

## Testing Accessibility

```typescript
// Using jest-axe
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('should not have accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});

// Testing keyboard navigation
test('should navigate with keyboard', () => {
  const { getByRole } = render(<Dropdown options={options} />);
  const button = getByRole('button');

  // Open with Enter
  fireEvent.keyDown(button, { key: 'Enter' });
  expect(getByRole('listbox')).toBeInTheDocument();

  // Navigate with ArrowDown
  fireEvent.keyDown(button, { key: 'ArrowDown' });
  // Assert selection

  // Close with Escape
  fireEvent.keyDown(button, { key: 'Escape' });
  expect(queryByRole('listbox')).not.toBeInTheDocument();
});

// Testing screen reader announcements
test('should announce loading state', () => {
  const { getByRole } = render(<LoadingComponent />);
  const liveRegion = getByRole('status');
  expect(liveRegion).toHaveAttribute('aria-live', 'polite');
  expect(liveRegion).toHaveTextContent('Loading');
});
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
