# Testing Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agents 13, 14, 15, 16, 18
**Purpose**: Comprehensive testing strategies

---

## AAA Pattern (Arrange, Act, Assert)

```typescript
describe('User', () => {
  it('should create user with valid data', () => {
    // Arrange
    const email = 'test@example.com';
    const name = 'Test User';

    // Act
    const result = User.create({ email, name });

    // Assert
    expect(result.isSuccess).toBe(true);
    const user = result.getValue();
    expect(user.email.value).toBe(email);
    expect(user.name).toBe(name);
  });
});
```

---

## Mock Patterns (Jest)

### mockResolvedValue vs mockReturnValue

```typescript
// ASYNC function - use mockResolvedValue
const mockRepository = {
  findById: jest.fn().mockResolvedValue(user),  // Returns Promise<User>
  save: jest.fn().mockResolvedValue(undefined), // Returns Promise<void>
};

// SYNC function - use mockReturnValue
const mockValidator = {
  validate: jest.fn().mockReturnValue(true), // Returns boolean
};

// WRONG - async/sync mismatch
mockRepository.findById.mockReturnValue(user); // BAD - returns User, not Promise<User>
```

### Mock Implementation

```typescript
const mockEmailService = {
  send: jest.fn().mockImplementation(async (to: string, subject: string) => {
    if (!to.includes('@')) {
      throw new Error('Invalid email');
    }
    return { success: true };
  }),
};
```

---

## MSW (Mock Service Worker)

```typescript
// mocks/handlers.ts
import { rest } from 'msw';

export const handlers = [
  rest.get('/api/users', (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json([
        { id: '1', name: 'User 1', email: 'user1@example.com' },
        { id: '2', name: 'User 2', email: 'user2@example.com' },
      ])
    );
  }),

  rest.post('/api/users', async (req, res, ctx) => {
    const body = await req.json();
    return res(
      ctx.status(201),
      ctx.json({ id: '3', ...body })
    );
  }),

  rest.delete('/api/users/:id', (req, res, ctx) => {
    return res(ctx.status(204));
  }),
];

// mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// test/setup.ts
import { server } from '../mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Usage in test
test('should fetch users', async () => {
  const { result } = renderHook(() => useUsers());

  await waitFor(() => {
    expect(result.current.data).toHaveLength(2);
  });
});
```

---

## Coverage Requirements

```json
// jest.config.js or vitest.config.ts
{
  "coverageThreshold": {
    "global": {
      "statements": 80,
      "branches": 75,
      "functions": 80,
      "lines": 80
    },
    "src/modules/**/domain/**/*.ts": {
      "statements": 100,
      "branches": 100,
      "functions": 100,
      "lines": 100
    }
  }
}
```

---

## DDD-Specific Testing

### Testing Factory Methods

```typescript
describe('User.create', () => {
  it('should create user with valid data', () => {
    const result = User.create({
      email: 'test@example.com',
      name: 'Test',
    });

    expect(result.isSuccess).toBe(true);
    const user = result.getValue();
    expect(user).toBeInstanceOf(User);
  });

  it('should fail with invalid email', () => {
    const result = User.create({
      email: 'invalid',
      name: 'Test',
    });

    expect(result.isFailure).toBe(true);
    expect(result.error).toContain('email');
  });
});
```

### Testing Result<T> Pattern

```typescript
describe('ChangeEmailUseCase', () => {
  it('should change email successfully', async () => {
    const user = User.create({ email: 'old@example.com', name: 'Test' }).getValue();
    mockRepository.findById.mockResolvedValue(user);
    mockRepository.save.mockResolvedValue(undefined);

    const result = await useCase.execute({
      userId: user.id,
      newEmail: 'new@example.com',
    });

    expect(result.isSuccess).toBe(true);
    expect(mockRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        _email: expect.objectContaining({ _value: 'new@example.com' })
      })
    );
  });

  it('should fail with invalid email', async () => {
    const user = User.create({ email: 'old@example.com', name: 'Test' }).getValue();
    mockRepository.findById.mockResolvedValue(user);

    const result = await useCase.execute({
      userId: user.id,
      newEmail: 'invalid',
    });

    expect(result.isFailure).toBe(true);
    expect(mockRepository.save).not.toHaveBeenCalled();
  });
});
```

### Testing Value Objects

```typescript
describe('Email', () => {
  it('should create valid email', () => {
    const result = Email.create('test@example.com');

    expect(result.isSuccess).toBe(true);
    expect(result.getValue().value).toBe('test@example.com');
  });

  it('should normalize email', () => {
    const result = Email.create('  TEST@EXAMPLE.COM  ');

    expect(result.isSuccess).toBe(true);
    expect(result.getValue().value).toBe('test@example.com');
  });

  it('should validate format', () => {
    const invalid = Email.create('invalid');
    expect(invalid.isFailure).toBe(true);
  });

  it('should compare emails', () => {
    const email1 = Email.create('test@example.com').getValue();
    const email2 = Email.create('test@example.com').getValue();
    const email3 = Email.create('other@example.com').getValue();

    expect(email1.equals(email2)).toBe(true);
    expect(email1.equals(email3)).toBe(false);
  });
});
```

---

## Test Isolation

```typescript
describe('ProjectService', () => {
  let service: ProjectService;
  let mockRepository: jest.Mocked<IProjectRepository>;

  beforeEach(() => {
    // Fresh mocks for each test
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
      delete: jest.fn(),
    };

    service = new ProjectService(mockRepository);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('test 1', async () => {
    // This test won't affect test 2
  });

  it('test 2', async () => {
    // Clean mocks from test 1
  });
});
```

---

## Integration Testing

```typescript
// test/integration/project.integration.spec.ts
describe('Project Integration Tests', () => {
  let app: INestApplication;
  let projectRepository: Repository<ProjectEntity>;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    projectRepository = moduleFixture.get('ProjectEntityRepository');
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    await projectRepository.clear();
  });

  it('should create project via API', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/projects')
      .send({ name: 'Test Project', description: 'Test' })
      .expect(201);

    const project = response.body;
    expect(project).toMatchObject({
      name: 'Test Project',
      description: 'Test',
    });

    // Verify persistence
    const saved = await projectRepository.findOne({ where: { id: project.id } });
    expect(saved).toBeDefined();
  });
});
```

---

## E2E Testing (Playwright)

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('should login successfully', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Dashboard');
  });

  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'wrong@example.com');
    await page.fill('input[name="password"]', 'wrong');
    await page.click('button[type="submit"]');

    await expect(page.locator('[role="alert"]')).toContainText('Invalid credentials');
  });
});
```

---

## Test Naming Conventions

```typescript
// Good - describes behavior
it('should return error when email is invalid');
it('should create user with valid data');
it('should prevent duplicate emails');

// Bad - describes implementation
it('should call validator.validate');
it('should set email property');
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
