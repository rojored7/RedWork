# UX Design System Patterns

Reference skill for Agent 16 (Frontend Development). Contains design token definitions, component visual standards, page-level UX patterns, and accessibility checklist.

---

## 1. Design Tokens — Tailwind Config Example

```typescript
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50:  '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',  // base
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        secondary: {
          50:  '#f5f3ff',
          100: '#ede9fe',
          200: '#ddd6fe',
          300: '#c4b5fd',
          400: '#a78bfa',
          500: '#8b5cf6',  // base
          600: '#7c3aed',
          700: '#6d28d9',
          800: '#5b21b6',
          900: '#4c1d95',
        },
        neutral: {
          50:  '#fafafa',
          100: '#f5f5f5',
          200: '#e5e5e5',
          300: '#d4d4d4',
          400: '#a3a3a3',
          500: '#737373',
          600: '#525252',
          700: '#404040',
          800: '#262626',
          900: '#171717',
        },
        success: { light: '#dcfce7', DEFAULT: '#16a34a', dark: '#166534' },
        warning: { light: '#fef3c7', DEFAULT: '#d97706', dark: '#92400e' },
        error:   { light: '#fee2e2', DEFAULT: '#dc2626', dark: '#991b1b' },
        info:    { light: '#dbeafe', DEFAULT: '#2563eb', dark: '#1e40af' },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      fontSize: {
        xs:   ['0.75rem',  { lineHeight: '1rem',    letterSpacing: '0.01em' }],
        sm:   ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0' }],
        base: ['1rem',     { lineHeight: '1.5rem',  letterSpacing: '0' }],
        lg:   ['1.125rem', { lineHeight: '1.75rem', letterSpacing: '-0.01em' }],
        xl:   ['1.25rem',  { lineHeight: '1.75rem', letterSpacing: '-0.01em' }],
        '2xl': ['1.5rem',  { lineHeight: '2rem',    letterSpacing: '-0.02em' }],
        '3xl': ['1.875rem',{ lineHeight: '2.25rem', letterSpacing: '-0.02em' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem',  letterSpacing: '-0.03em' }],
      },
      spacing: {
        '0': '0', '1': '0.25rem', '2': '0.5rem', '3': '0.75rem',
        '4': '1rem', '5': '1.25rem', '6': '1.5rem', '8': '2rem',
        '10': '2.5rem', '12': '3rem', '16': '4rem', '20': '5rem', '24': '6rem',
      },
      borderRadius: {
        none: '0', sm: '0.25rem', DEFAULT: '0.5rem',
        lg: '0.75rem', xl: '1rem', full: '9999px',
      },
      boxShadow: {
        sm:  '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        DEFAULT: '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
        md:  '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
        lg:  '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
        xl:  '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)',
      },
      zIndex: {
        dropdown: '10', sticky: '20', 'modal-backdrop': '30',
        modal: '40', toast: '50', tooltip: '60',
      },
      transitionDuration: {
        fast: '150ms', normal: '300ms', slow: '500ms',
      },
      keyframes: {
        'shimmer': {
          '0%':   { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
        'fade-in': {
          '0%':   { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'slide-in-right': {
          '0%':   { transform: 'translateX(100%)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' },
        },
        'scale-in': {
          '0%':   { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
      animation: {
        'shimmer':        'shimmer 2s ease-in-out infinite',
        'fade-in':        'fade-in 300ms ease-out',
        'slide-in-right': 'slide-in-right 300ms ease-out',
        'scale-in':       'scale-in 300ms ease-out',
      },
    },
  },
  plugins: [],
};

export default config;
```

---

## 2. Design Tokens — CSS Custom Properties (Alternative)

```css
/* tokens.css — import in app root */
:root {
  /* Colors */
  --color-primary-50: #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-700: #1d4ed8;
  --color-neutral-50: #fafafa;
  --color-neutral-200: #e5e5e5;
  --color-neutral-500: #737373;
  --color-neutral-800: #262626;
  --color-neutral-900: #171717;
  --color-success: #16a34a;
  --color-warning: #d97706;
  --color-error: #dc2626;
  --color-info: #2563eb;

  /* Typography */
  --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  /* Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);

  /* Motion */
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in: cubic-bezier(0.55, 0.06, 0.68, 0.19);

  /* Z-Index */
  --z-dropdown: 10;
  --z-sticky: 20;
  --z-modal-backdrop: 30;
  --z-modal: 40;
  --z-toast: 50;
  --z-tooltip: 60;
}

@media (prefers-reduced-motion: reduce) {
  :root {
    --duration-fast: 0ms;
    --duration-normal: 0ms;
    --duration-slow: 0ms;
  }
}
```

---

## 3. Component Visual Standards

### Button

```tsx
// Variants: primary | secondary | ghost | destructive | link
// Sizes: sm | md | lg
// States: default | hover | focus | active | disabled | loading

// Visual behavior per state:
// hover:    background darkens 1 shade, cursor: pointer
// focus:    2px ring, 2px offset, primary-500 color (:focus-visible only)
// active:   scale(0.97) transform
// disabled: opacity 0.5, cursor: not-allowed, no hover effect
// loading:  spinner icon replaces text, disabled behavior

<Button variant="primary" size="md" loading={isSubmitting}>
  Save Changes
</Button>
```

### Input

```tsx
// States: default | hover | focus | error | disabled

// Visual behavior:
// default:  border neutral-300, bg white
// hover:    border neutral-400
// focus:    border primary-500, ring-2 primary-500/20
// error:    border error, ring-2 error/20, error icon suffix
// disabled: bg neutral-100, text neutral-400, cursor not-allowed

// Layout:
// <label>     — above, font-medium text-sm text-neutral-700
// <input>     — full width, rounded-md, px-3 py-2
// <helper>    — below, text-xs text-neutral-500 (hidden when error shows)
// <error>     — below, text-xs text-error, icon prefix

<FormField label="Email" helper="We'll never share your email" error={errors.email}>
  <Input type="email" placeholder="you@example.com" />
</FormField>
```

### Skeleton Loader

```tsx
// Shimmer animation: left-to-right gradient pulse
// Match the SHAPE of the content being loaded (not a generic spinner)

// For text:
<Skeleton className="h-4 w-3/4 rounded" />

// For avatar:
<Skeleton className="h-10 w-10 rounded-full" />

// For card:
<Skeleton className="h-48 w-full rounded-lg" />

// For table row:
<div className="flex gap-4">
  <Skeleton className="h-4 w-1/4" />
  <Skeleton className="h-4 w-1/3" />
  <Skeleton className="h-4 w-1/6" />
  <Skeleton className="h-4 w-1/4" />
</div>
```

### Toast Notification

```tsx
// Position: top-right (desktop) or top-center (mobile)
// Entry: slide-in from right + slight bounce
// Duration: 5 seconds auto-dismiss
// Dismiss: click X or swipe (mobile)
// Variants: success (green), error (red), warning (amber), info (blue)

// Structure:
// [icon] [title]                    [X]
//        [description]

toast.success("Project created", "Your new project is ready to use.");
toast.error("Save failed", "Could not reach the server. Please try again.");
```

### Empty State

```tsx
// Structure:
// [icon or illustration]
// [heading — what's empty]
// [description — why it's empty or what to do]
// [CTA button — primary action to fill it]

<EmptyState
  icon={<FolderOpen className="h-12 w-12 text-neutral-400" />}
  title="No projects yet"
  description="Create your first project to get started."
  action={<Button variant="primary">Create Project</Button>}
/>
```

### Error Page (404)

```tsx
// Structure:
// [large error code or illustration]
// [human-readable message]
// [suggestion + navigation links]

<ErrorPage
  code="404"
  title="Page not found"
  description="The page you're looking for doesn't exist or has been moved."
  actions={
    <>
      <Button variant="primary" onClick={() => navigate('/')}>
        Go to Dashboard
      </Button>
      <Button variant="ghost" onClick={() => navigate(-1)}>
        Go Back
      </Button>
    </>
  }
/>
```

---

## 4. Page Layout Patterns

### Dashboard Layout

```
+--------------------------------------------------+
| [logo]  [nav items]           [user avatar] [bell]|  <- TopBar (sticky)
+--------+-----------------------------------------+
|        |                                         |
| [nav]  |  [breadcrumb]                           |
| [item] |  [page title]          [action buttons] |
| [item] |                                         |
| [item] |  [content area]                         |
| [item] |                                         |
|  ...   |                                         |
|        |                                         |
+--------+-----------------------------------------+
```

- Sidebar: collapsible on desktop, drawer on mobile
- Content area: max-width container (1280px) with horizontal padding
- Sticky topbar with user menu dropdown

### Auth Layout

```
+--------------------------------------------------+
|                                                    |
|     [logo]                                         |
|                                                    |
|     +----------------------------------+           |
|     | [form title]                     |           |
|     | [form fields]                    |           |
|     | [submit button]                  |           |
|     | [secondary link]                 |           |
|     +----------------------------------+           |
|                                                    |
|     [footer links]                                 |
+--------------------------------------------------+
```

- Centered card on neutral/gradient background
- Max-width 400px for the form card
- Logo above the card

---

## 5. Accessibility Visual Checklist

### Contrast (WCAG AA)

| Element | Minimum Ratio |
|---|---|
| Normal text (< 18px) | 4.5:1 |
| Large text (>= 18px or >= 14px bold) | 3:1 |
| UI components (borders, icons) | 3:1 |
| Focus indicators | 3:1 against adjacent colors |

### Focus

- `:focus-visible` ring: 2px solid primary-500, 2px offset
- Never `outline: none` without a replacement
- Tab order follows visual reading order
- Escape key closes modals, dropdowns, tooltips

### Keyboard

| Pattern | Keys |
|---|---|
| Navigate between elements | Tab / Shift+Tab |
| Activate button/link | Enter or Space |
| Close modal/dropdown | Escape |
| Navigate dropdown items | Arrow Up/Down |
| Select dropdown item | Enter |
| Toggle checkbox | Space |
| Navigate tabs | Arrow Left/Right |

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Semantic HTML Priority

Use in this order (first available wins):

1. Native HTML element (`<button>`, `<a>`, `<nav>`, `<dialog>`)
2. HTML with implicit roles (`<main>`, `<header>`, `<footer>`, `<article>`, `<section>`)
3. ARIA role + attributes (only when 1 and 2 are insufficient)

### Screen Reader

- Images: `alt="description"` or `alt=""` for decorative
- Icons: `aria-hidden="true"` + adjacent text label, or `aria-label`
- Live regions: `aria-live="polite"` for toast notifications
- Form errors: `aria-describedby` linking input to error message
- Loading states: `aria-busy="true"` + `aria-live="polite"` announcement

---

## 6. Form Layout Pattern

```
Label Text *                          <- font-medium, text-sm, required indicator
+--------------------------------------+
| Placeholder text                     |  <- input with proper padding
+--------------------------------------+
Helper text explaining the field         <- text-xs, text-neutral-500

-- ON ERROR: --

Label Text *                          <- stays same
+--------------------------------------+
| Invalid value                        |  <- border-error, ring-error/20
+--------------------------------------+
[!] Error message for this field        <- text-xs, text-error, icon prefix
```

Rules:
- Label is ALWAYS above the input (not floating, not to the side)
- Helper text disappears when error text appears (same position)
- Error icon (exclamation) prefixes the error message
- Required fields marked with `*` after label
- First field auto-focused on form mount
- Submit button shows spinner + "Saving..." when submitting
- Multi-step: progress bar at top showing current/total steps
