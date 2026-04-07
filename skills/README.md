# Framework Skills - Centralized Knowledge Base

**Version**: 1.0
**Created**: 2026-04-07
**Purpose**: Centralized, reusable knowledge that agents REFERENCE instead of duplicating

---

## What are Skills?

Skills are centralized knowledge documents that contain:
- Common patterns used across multiple agents
- Complete implementations with examples
- Best practices and anti-patterns
- Decision frameworks

**Agents REFERENCE skills instead of duplicating content.**

---

## Available Skills

### Core Architecture & Patterns

#### 1. DDD/Clean Architecture (`ddd-clean-architecture.md`)
**Used by**: Agents 02, 05, 10, 13, 15, 09b

**Contains**:
- Private constructor + factory method pattern
- Result<T> pattern for error handling
- Immutable value objects
- Repository pattern (interfaces + implementation)
- Mapper patterns (Domain ↔ ORM)
- Layer separation rules
- Complete Entity, Value Object, Repository examples
- Anti-patterns to avoid

**Size**: ~400 lines

---

### Testing

#### 2. Testing Patterns (`testing-patterns.md`)
**Used by**: Agents 13, 14, 15, 16, 18

**Contains**:
- AAA pattern (Arrange, Act, Assert)
- Mock patterns (Jest, MSW)
- Coverage requirements (80%/75%/80%/80%)
- DDD-specific testing (factory methods, Result<T>)
- Test isolation strategies
- Unit, Integration, E2E test examples

**Size**: ~350 lines

---

### Security

#### 3. Security Best Practices (`security-best-practices.md`)
**Used by**: Agents 10, 11, 19

**Contains**:
- OWASP Top 10 coverage
- Input validation patterns
- XSS prevention (DOMPurify)
- CSRF protection
- Secure token storage
- SQL injection prevention
- Authentication/authorization patterns
- Complete security implementation examples

**Size**: ~300 lines

---

### Code Quality

#### 4. TypeScript Quality Standards (`typescript-quality-standards.md`)
**Used by**: Agents 10, 11, 20

**Contains**:
- TypeScript strict mode enforcement
- No `any` types policy
- Linting rules (0 errors, 0 warnings)
- Code organization patterns
- Naming conventions
- Discriminated unions, type guards, branded types
- Import organization

**Size**: ~250 lines

---

### React/Frontend Patterns

#### 5. React Component Patterns (`react-component-patterns.md`)
**Used by**: Agent 11

**Contains**:
- Compound components
- Render props pattern
- Custom hooks (useForm, useDebounce, useLocalStorage, useIntersectionObserver)
- Higher-Order Components (withAuth, withErrorBoundary)
- Component composition strategies

**Size**: ~500 lines

#### 6. State Management Patterns (`state-management-patterns.md`)
**Used by**: Agent 11

**Contains**:
- Context + Reducer pattern
- Zustand global state
- React Query server state
- State colocation strategies
- Complete implementation examples

**Size**: ~400 lines

#### 7. Performance Optimization (`performance-optimization.md`)
**Used by**: Agent 11

**Contains**:
- Memoization (useMemo, useCallback, memo)
- Code splitting (lazy, Suspense)
- Virtualization (tanstack virtual)
- Image optimization
- Debounce/throttle patterns

**Size**: ~300 lines

#### 8. Accessibility Patterns (`accessibility-patterns.md`)
**Used by**: Agent 11

**Contains**:
- Semantic HTML
- ARIA labels, roles, states
- Keyboard navigation
- Focus management
- Screen reader support
- WCAG AA compliance
- Color contrast requirements

**Size**: ~300 lines

---

### Configuration & Integration

#### 9. Configuration Management (`configuration-management.md`)
**Used by**: Agents 10, 11, 12

**Contains**:
- No hardcoded values rule
- Centralized configuration pattern
- Environment variable validation
- Typed configuration objects
- Secret management
- .env file patterns

**Size**: ~200 lines

#### 10. API Client Patterns (`api-client-patterns.md`)
**Used by**: Agents 10, 11, 15

**Contains**:
- Centralized API client
- Request/response typing
- Error handling patterns
- Token injection
- Retry logic
- Base URL configuration

**Size**: ~200 lines

---

## How to Use Skills in Agents

### Pattern: Reference + Quick Guide

```markdown
## [Topic] Requirements

**Primary Reference**: `framework/skills/[skill-name].md`

**Key Points** (see skill for full details):
- Key point 1
- Key point 2
- Key point 3

**Quick Example**:
```typescript
// Minimal example showing the pattern
```

**Common Mistakes**: See skill Section X for anti-patterns.

For complete patterns, examples, and decision frameworks, consult the skill document.
```

### Example: DDD in Agent

```markdown
## DDD/Clean Architecture Requirements

**Primary Reference**: `framework/skills/ddd-clean-architecture.md`

**Key Points**:
- Entities: Private constructor + static create() returning Result<T>
- Value Objects: Immutable + static create() returning Result<T>
- NO casting to entities, NO public constructors, NO exceptions in domain

**Quick Example**:
```typescript
export class User {
  private constructor(props) { /* ... */ }
  public static create(props): Result<User> { /* ... */ }
}
```

For complete implementations, mappers, repositories, and anti-patterns, see the skill.
```

---

## Skill Creation Guidelines

### When to Create a Skill

Create a skill when:
- Pattern appears in 3+ agents (duplication threshold)
- Content is >100 lines
- Knowledge is stable and reusable
- Pattern is framework-level (not project-specific)

### Skill Structure

Every skill should have:

1. **Overview** - What this skill covers
2. **When to Use** - Decision framework
3. **Core Concepts** - Theoretical foundation
4. **Implementation Patterns** - How to implement
5. **Complete Examples** - Working code
6. **Anti-Patterns** - What NOT to do
7. **Decision Trees** - When to use pattern A vs B
8. **References** - External resources

### Skill Maintenance

- Skills are versioned (v1.0, v1.1, etc.)
- Breaking changes documented in skill changelog
- Agents reference skill version (optional)
- Skills reviewed quarterly for updates

---

## Statistics

**Total Skills**: 10
**Total Lines**: ~3,200 lines
**Agents Using Skills**: 13 agents
**Duplication Eliminated**: ~2,380 lines across agents
**Framework Size Reduction**: 26% in consuming agents

---

## Benefits

### For Developers
- Single source of truth for patterns
- Comprehensive examples in one place
- Easier to find and learn patterns
- Consistent terminology

### For Agents
- Reduced size (compliance with 1,500 line policy)
- Focus on agent-specific logic
- Reference authority without duplication
- Easier maintenance (update skill once, all agents benefit)

### For Framework
- Better organization
- Extensible (add skills without agent bloat)
- Measurable quality (skills define standards)
- Version-controlled knowledge

---

## Roadmap

### v1.0 (Current)
- 10 core skills created
- Agent 11 brought into compliance
- Major duplication eliminated

### v1.1 (Planned)
- Skill 11: Form Validation Patterns
- Skill 12: Animation Patterns
- Skill 13: Error Handling Strategies
- Skill versioning system

### v2.0 (Future)
- Interactive skill examples
- Skill dependency graph
- Auto-generated skill index
- Skill usage analytics

---

**Framework Version**: 1.3.0
**Skills Version**: 1.0
**Last Updated**: 2026-04-07
**Maintainer**: Framework Team
