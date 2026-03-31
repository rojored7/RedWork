# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ MANDATORY PROTOCOL

**BEFORE doing ANY code development, ALWAYS read:**

1. **`docs/INICIALIZACION_FRAMEWORK.md`** - Mandatory protocol for ALL agents. This document contains non-negotiable rules about TDD, DDD, Clean Architecture, GATES, and execution verification.
2. **`09_sprint_plan/sprint_XX/CLAUDE.md`** - Sprint-specific context and requirements (where XX is the current sprint number)
3. **`docs/PLAN_DESARROLLO_SPRINT.md`** - Complete sprint development methodology

**NEVER write code without reading the framework initialization document first.**

---

## Project Overview

**Task Manager MVP** - A modern task management application built with Domain-Driven Design (DDD), Test-Driven Development (TDD), and Clean Architecture principles.

### Technology Stack

- **Backend**: NestJS + TypeScript + TypeORM
- **Frontend**: React 18 + TypeScript + Vite + TailwindCSS
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Testing**: Jest (backend), Vitest (frontend), Playwright (E2E)
- **Architecture**: Modular Monolith with Clean Architecture

---

## Essential Commands

### Root Level (Monorepo)

```bash
# Install all dependencies
npm install

# Run backend in development
npm run backend
# Or: cd backend && npm run start:dev

# Run frontend in development
npm run frontend
# Or: cd frontend && npm run dev

# Build everything
npm run build

# Run all tests
npm test

# Lint everything
npm run lint

# Format code
npm run format
```

### Backend Commands

```bash
cd backend

# Development
npm run start:dev          # Start with hot reload (port 3000)
npm run start:debug        # Start with debugger

# Building
npm run build             # Compile TypeScript (MANDATORY after each wave)

# Testing
npm test                  # Run unit tests
npm run test:watch        # Run tests in watch mode
npm run test:cov          # Run tests with coverage
npm run test:integration  # Run integration tests (requires DB/Redis UP)
npm run test:e2e          # Run E2E tests

# Code Quality
npm run lint              # Run ESLint
npm run format            # Format with Prettier

# Database
npm run typeorm migration:run     # Run migrations
npm run typeorm migration:revert  # Revert last migration
```

### Frontend Commands

```bash
cd frontend

# Development
npm run dev               # Start dev server (port 3010)
npm run build             # Build for production
npm run preview           # Preview production build

# Testing
npm run test              # Run unit tests with Vitest
npm run test:ui           # Run tests with UI
npm run test:coverage     # Run tests with coverage
npx playwright test       # Run E2E tests

# Code Quality
npm run lint              # Run ESLint
npm run format            # Format with Prettier
npm run type-check        # TypeScript type checking
```

### Docker Commands

```bash
# Start infrastructure (PostgreSQL + Redis)
docker-compose up -d

# Check service health
docker ps

# View logs
docker-compose logs -f postgres
docker-compose logs -f redis

# Stop services
docker-compose down

# Clean restart (removes data)
docker-compose down -v && docker-compose up -d
```

---

## Architecture Overview

### Clean Architecture Layers (Backend)

```
┌─────────────────────────────────────┐
│  4. API Layer (Controllers)        │  ← HTTP, DTOs, Validators
│     ↓                               │
│  3. Infrastructure (Adapters)      │  ← TypeORM, Redis, S3, External APIs
│     ↓                               │
│  2. Application (Use Cases)        │  ← Services, DTOs, Business Logic
│     ↓                               │
│  1. Domain (Core Business Logic)   │  ← Entities, VOs, Business Rules
└─────────────────────────────────────┘

DEPENDENCIES FLOW INWARD ONLY
- Domain: No dependencies on other layers
- Application: Depends only on Domain
- Infrastructure: Depends on Application and Domain
- API: Depends on all layers
```

### Module Structure (Backend)

```
backend/src/modules/{module-name}/
├── domain/
│   ├── entities/              # Domain entities (pure business logic)
│   ├── value-objects/         # Immutable value objects
│   ├── repositories/          # Repository interfaces (ports)
│   └── services/              # Domain services (optional)
├── application/
│   ├── services/              # Application services (use cases)
│   ├── dto/                   # Data Transfer Objects
│   └── ports/                 # Output ports (interfaces)
├── infrastructure/
│   ├── persistence/           # TypeORM entities & repositories
│   │   ├── entities/          # ORM entities
│   │   ├── repositories/      # Repository implementations
│   │   └── mappers/           # Domain ↔ ORM mappers
│   └── adapters/              # External service adapters
└── api/
    ├── controllers/           # HTTP controllers
    ├── dto/                   # API DTOs
    ├── guards/                # Auth guards
    └── decorators/            # Custom decorators
```

### Frontend Architecture

```
frontend/src/
├── modules/{module-name}/
│   ├── components/        # React components
│   ├── hooks/             # Custom React hooks
│   ├── services/          # API services
│   ├── stores/            # Zustand stores
│   └── types/             # TypeScript types
├── shared/
│   ├── components/        # Reusable UI components
│   ├── hooks/             # Shared hooks
│   ├── lib/               # Utilities
│   └── types/             # Shared types
└── config/                # Configuration
```

---

## Critical Development Rules

### REGLA #1: TDD is Mandatory

```
RED → GREEN → REFACTOR

1. Write test FIRST (it must FAIL)
2. Implement minimum code to make it PASS
3. Refactor without breaking tests

NEVER write code without a test first.
```

### REGLA #2: Backend MUST Compile

```bash
npm run build

# MUST show: 0 errors
# If it fails: STOP and fix ALL errors before continuing
```

**Critical**: After EVERY significant change, run `npm run build`. A backend that doesn't compile cannot run.

### REGLA #3: Tests MUST Execute

```
❌ WRONG: "I created test files"
✅ RIGHT: "Tests executed: 44 passing, 100% coverage"

Creating test files ≠ Executing tests
```

Always provide ACTUAL output from test execution, not summaries.

### REGLA #4: GATES Require 100% (Not "Framework Works")

A **GATE** is a checkpoint that validates **100% tests passing** before continuing.

```
┌────────────────────────────────────────────────────────────┐
│  ❌ WRONG GATE DEFINITION:                                 │
│  "Integration Tests: FRAMEWORK OK (6/17 tests passing)"   │
│                                                             │
│  ✅ CORRECT GATE DEFINITION:                               │
│  "Integration Tests: 100% PASSING (17/17 tests)"          │
│                                                             │
│  GATE = 100% tests passing (NOT "tests execute")          │
│  GATE = 0 compilation errors (NOT "most files compile")   │
│  GATE = 100% coverage (NOT "80% coverage")                 │
└────────────────────────────────────────────────────────────┘

GATE FAILED = SPRINT BLOCKED

If a gate shows anything less than 100%:
1. ❌ STOP immediately - DO NOT continue
2. 📊 Report ACTUAL numbers (not "mostly passing")
3. 🔧 FIX ALL failing tests/errors
4. ✅ VERIFY gate shows 100%
5. ✅ ONLY THEN continue

Example of CORRECT gate reporting:
- ✅ "Tests: 102/102 passing (100%)"
- ✅ "Compilation: 0 errors"
- ✅ "Coverage: 100%"

Example of INCORRECT gate reporting:
- ❌ "Tests: FRAMEWORK OK" (hides that only 35% passing)
- ❌ "Compilation: SUCCESS" (hides warnings/errors)
- ❌ "Coverage: Good" (hides it's only 80%)
```

See `docs/INICIALIZACION_FRAMEWORK.md` for complete GATES and HOOKS documentation.

### REGLA #5: Definition of "Complete"

Work is ONLY complete when ALL of the following show 100%:

```markdown
## A Feature/Wave is "COMPLETE" When:

✅ 1. **Compilation**: 0 errors
   Command: `npm run build`
   Expected: Build succeeded with 0 errors

✅ 2. **Unit Tests**: 100% passing
   Command: `npm test`
   Expected: X tests passing, 0 failing

✅ 3. **Coverage**: 100%
   Command: `npm test -- --coverage`
   Expected: All files show 100% coverage

✅ 4. **Integration Tests**: 100% passing (if applicable)
   Command: `npm run test:integration`
   Expected: X tests passing, 0 failing

✅ 5. **E2E Tests**: 100% passing (for sprint features)
   Command: `npx playwright test`
   Expected: X tests passing, 0 failing

✅ 6. **Linting**: 0 errors, 0 warnings
   Command: `npm run lint`
   Expected: Clean output

✅ 7. **Manual Validation**: Feature works in running app
   - Backend starts without errors
   - Frontend loads without console errors
   - Feature functions as expected

**NONE OF THESE ARE OPTIONAL**
**100% OR NOTHING**
```

If ANY of these shows less than 100%, the work is **INCOMPLETE** and must be fixed.

---

## Sprint Development Protocol

### Wave Structure

Each sprint is divided into 5 waves:

1. **Wave 1: Domain Layer** - Entities, VOs, Business Rules
2. **Wave 2: Application Layer** - Services, Use Cases
3. **Wave 3: API Layer** - Controllers, DTOs, Endpoints
4. **Wave 4: Frontend** - Components, Pages, API Integration
5. **Wave 5: Testing** - Integration + E2E Tests

### Mandatory Commands Per Wave

**Wave 1 (Domain)**:
```bash
npm test -- --testPathPattern="domain"
npm test -- --testPathPattern="domain" --coverage
npm run build  # ⚠️ CRITICAL
```

**Wave 2 (Application)**:
```bash
npm test -- --testPathPattern="application"
npm test -- --testPathPattern="application" --coverage
npm run build  # ⚠️ CRITICAL
npm test  # Verify no regressions
```

**Wave 3 (API)**:
```bash
npm test -- --testPathPattern="api"
npm run build  # ⚠️ CRITICAL
npm run start:dev  # ⚠️ MUST start successfully
curl http://localhost:3000/health  # Smoke test
```

**Wave 4 (Frontend)**:
```bash
cd frontend
npm run build  # ⚠️ CRITICAL
npm run test
npm run dev  # ⚠️ MUST start successfully
```

**Wave 5 (Testing)**:
```bash
# Backend running in terminal 1
cd backend && npm run start:dev

# Frontend running in terminal 2
cd frontend && npm run dev

# Integration tests
cd backend && npm run test:integration

# E2E tests
npx playwright test
```

---

## Testing Strategy

### Test Types and Coverage

| Test Type | Tool | Coverage Target | When to Run |
|-----------|------|----------------|-------------|
| Unit Tests | Jest/Vitest | >100% | After every code change |
| Integration Tests | Jest | >100% | After Wave 2 complete |
| E2E Tests | Playwright | Critical paths | After Wave 5 complete |

### Test Naming Convention

```typescript
// Unit test
describe('TaskEntity', () => {
  describe('create', () => {
    it('should create a valid task with required fields', () => {
      // Arrange
      const props = { title: 'Test', userId: 'user-1' };

      // Act
      const task = Task.create(props);

      // Assert
      expect(task.title).toBe('Test');
    });
  });
});
```

### Test Execution Verification

Every test report MUST include:
- Number of tests executed
- Number of tests passing/failing
- Coverage percentage
- ACTUAL command output (not summaries)

---

## Common Patterns

### Domain Entity Pattern

```typescript
// backend/src/modules/task/domain/entities/task.entity.ts
export class Task {
  private constructor(
    public readonly id: string,
    private _title: string,
    private _status: TaskStatus,
    // ... other properties
  ) {}

  static create(props: TaskProps): Task {
    // Validation
    if (!props.title || props.title.length === 0) {
      throw new Error('Title is required');
    }

    return new Task(
      props.id || uuid(),
      props.title,
      props.status || TaskStatus.TODO,
    );
  }

  get title(): string {
    return this._title;
  }

  changeStatus(newStatus: TaskStatus): void {
    if (!this._status.canTransitionTo(newStatus)) {
      throw new Error(`Cannot transition from ${this._status} to ${newStatus}`);
    }
    this._status = newStatus;
  }
}
```

### Repository Pattern

```typescript
// Domain interface (port)
export interface ITaskRepository {
  findById(id: string): Promise<Task | null>;
  save(task: Task): Promise<Task>;
  delete(id: string): Promise<void>;
  findByUserId(userId: string): Promise<Task[]>;
}

// Infrastructure implementation (adapter)
@Injectable()
export class TaskRepository implements ITaskRepository {
  constructor(
    @InjectRepository(TaskEntity)
    private readonly taskRepository: Repository<TaskEntity>,
  ) {}

  async findById(id: string): Promise<Task | null> {
    const entity = await this.taskRepository.findOne({ where: { id } });
    return entity ? TaskMapper.toDomain(entity) : null;
  }

  // ... other methods
}
```

### Mapper Pattern

```typescript
export class TaskMapper {
  static toDomain(entity: TaskEntity): Task {
    return Task.create({
      id: entity.id,
      title: entity.title,
      status: TaskStatus.fromString(entity.status),
      // ... other properties
    });
  }

  static toPersistence(task: Task): TaskEntity {
    const entity = new TaskEntity();
    entity.id = task.id;
    entity.title = task.title;
    entity.status = task.status.value;
    return entity;
  }
}
```

---

## Environment Configuration

### Backend Environment Variables

```bash
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=taskmanager_user
DATABASE_PASSWORD=your_password
DATABASE_NAME=taskmanager_dev

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_jwt_secret
JWT_EXPIRATION=1d

# Application
NODE_ENV=development
PORT=3000
```

### Frontend Environment Variables

```bash
VITE_API_URL=http://localhost:3000
VITE_API_TIMEOUT=10000
```

---

## Debugging

### Backend Debugging

```bash
# Start with debugger
npm run start:debug

# View detailed logs
DEBUG=* npm run start:dev

# Check TypeScript compilation
npm run build
```

### Frontend Debugging

```bash
# Check TypeScript types
npm run type-check

# Build to find issues
npm run build
```

### Database Debugging

```bash
# Access PostgreSQL CLI
docker exec -it taskmanager-postgres psql -U taskmanager_user -d taskmanager_dev

# Common queries
\dt              # List tables
\d+ tasks        # Describe tasks table
SELECT * FROM tasks LIMIT 10;
```

---

## Critical Files to Reference

1. **`docs/INICIALIZACION_FRAMEWORK.md`** - MANDATORY reading before any development
2. **`docs/PLAN_DESARROLLO_SPRINT.md`** - Complete sprint methodology
3. **`04_architecture_decision.md`** - Architectural decisions and rationale
4. **`05_service_design.md`** - Detailed service design specifications
5. **`09_sprint_plan/sprint_XX/CLAUDE.md`** - Sprint-specific context
6. **`README.md`** - Quick start and basic setup

---

## Port Configuration

| Service | Default Port | Actual Port | URL |
|---------|--------------|-------------|-----|
| Backend | 3000 | 3000 | http://localhost:3000 |
| Frontend | 5173 | 3010 | http://localhost:3010 |
| PostgreSQL | 5432 | 5432 | localhost:5432 |
| Redis | 6379 | 6379 | localhost:6379 |

**Note**: Ports may be adjusted in `.project-orchestration/runtime-infrastructure.json` if conflicts exist.

---

## Git Workflow

```bash
# Feature branch naming
git checkout -b feature/US-XXX-short-description
git checkout -b fix/bug-description
git checkout -b refactor/component-name

# Commit messages (follow Conventional Commits)
feat(task): add task creation endpoint
fix(auth): resolve token refresh issue
test(task): add unit tests for task entity
docs(readme): update setup instructions

# Before committing
npm run lint        # Fix linting issues
npm run format      # Format code
npm test            # Ensure tests pass
npm run build       # Ensure compilation succeeds
```

---

## Troubleshooting

### Backend Won't Start

1. Check if PostgreSQL and Redis are running: `docker ps`
2. Check environment variables are set correctly
3. Run `npm run build` to check for compilation errors
4. Check logs: `npm run start:dev` shows error details

### Tests Failing

1. Ensure database is running for integration tests
2. Check test isolation (each test should clean up after itself)
3. Run single test to isolate issue: `npm test -- --testNamePattern="test name"`
4. Check mock setup in test files

### Frontend Build Errors

1. Run `npm run type-check` to see TypeScript errors
2. Check import paths are correct
3. Ensure all dependencies are installed: `npm install`
4. Clear cache: `rm -rf node_modules/.vite && npm run dev`

---

## Performance Guidelines

- **Response Time**: API endpoints should respond in <200ms
- **Database Queries**: Use indexes, avoid N+1 queries
- **Caching**: Use Redis for frequently accessed data
- **Pagination**: Always paginate list endpoints (default: 20 items)
- **Test Execution**: Unit tests should complete in <5s, integration in <30s

---

## Security Considerations

- **Authentication**: JWT-based with refresh tokens
- **Authorization**: Role-based access control (RBAC)
- **Validation**: Use class-validator for all DTOs
- **SQL Injection**: TypeORM parameterized queries prevent this
- **XSS**: React escapes by default, but sanitize user input
- **CORS**: Configured in backend for specific origins only

---

## Contact & Support

For issues or questions:
1. Check `docs/INICIALIZACION_FRAMEWORK.md` for protocols
2. Review sprint-specific CLAUDE.md in `09_sprint_plan/sprint_XX/`
3. Check troubleshooting section above
4. Review logs: `docker-compose logs -f`

---

**Remember**: Quality over speed. Follow TDD, verify tests execute, ensure backend compiles with 0 errors before marking any work as complete.
