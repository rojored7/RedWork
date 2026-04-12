# Testing Patterns

**Skill Version**: 2.0
**Created**: 2026-04-07
**Updated**: 2026-04-11
**Used By**: Agents 13, 14, 15, 16, 18
**Purpose**: Comprehensive testing strategies
**Stack**: Backend = pytest (Python), Frontend = Vitest + Testing Library, E2E = Playwright

---

## AAA Pattern (Arrange, Act, Assert)

### Backend (pytest)

```python
def test_create_user_with_valid_data():
    # Arrange
    email = "test@example.com"
    name = "Test User"

    # Act
    result = User.create(email=email, name=name)

    # Assert
    assert result.is_success is True
    user = result.value
    assert user.email.value == email
    assert user.name == name
```

### Frontend (Vitest)

```typescript
import { describe, it, expect } from 'vitest';

describe('User', () => {
  it('should create user with valid data', () => {
    // Arrange
    const email = 'test@example.com';
    const name = 'Test User';

    // Act
    const result = createUser({ email, name });

    // Assert
    expect(result.isSuccess).toBe(true);
  });
});
```

---

## Mock Patterns

### Backend (unittest.mock)

```python
from unittest.mock import AsyncMock, MagicMock, patch

# ASYNC function - use AsyncMock
mock_repository = MagicMock()
mock_repository.find_by_id = AsyncMock(return_value=user)   # Returns awaitable
mock_repository.save = AsyncMock(return_value=None)          # Returns awaitable

# SYNC function - use MagicMock
mock_validator = MagicMock()
mock_validator.validate = MagicMock(return_value=True)       # Returns bool

# WRONG - async/sync mismatch
mock_repository.find_by_id = MagicMock(return_value=user)    # BAD - not awaitable

# Mock with side_effect (conditional behavior)
async def conditional_send(to: str, subject: str):
    if "@" not in to:
        raise ValueError("Invalid email")
    return {"success": True}

mock_email_service = MagicMock()
mock_email_service.send = AsyncMock(side_effect=conditional_send)
```

### Frontend (Vitest)

```typescript
import { vi } from 'vitest';

// ASYNC function
const mockFetch = vi.fn().mockResolvedValue({ data: user });

// SYNC function
const mockValidate = vi.fn().mockReturnValue(true);

// Conditional mock
const mockSend = vi.fn().mockImplementation(async (to: string) => {
  if (!to.includes('@')) throw new Error('Invalid email');
  return { success: true };
});
```

---

## MSW (Mock Service Worker) — Frontend Only

```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'User 1', email: 'user1@example.com' },
      { id: '2', name: 'User 2', email: 'user2@example.com' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: '3', ...body }, { status: 201 });
  }),

  http.delete('/api/users/:id', () => {
    return new HttpResponse(null, { status: 204 });
  }),
];

// mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// test/setup.ts (vitest)
import { beforeAll, afterEach, afterAll } from 'vitest';
import { server } from '../mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Usage in test
import { renderHook, waitFor } from '@testing-library/react';

test('should fetch users', async () => {
  const { result } = renderHook(() => useUsers());

  await waitFor(() => {
    expect(result.current.data).toHaveLength(2);
  });
});
```

---

## Coverage Requirements

### Backend (pyproject.toml)

```toml
[tool.pytest.ini_options]
addopts = "--cov=app --cov-report=term-missing --cov-fail-under=80"

[tool.coverage.run]
source = ["app"]
omit = ["app/tests/*", "app/migrations/*"]

[tool.coverage.report]
fail_under = 80
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
    "raise NotImplementedError",
]
```

### Frontend (vitest.config.ts)

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
    },
  },
});
```

Target: 80% global, 100% for domain layer.

---

## DDD-Specific Testing

### Testing Factory Methods (Backend — pytest)

```python
class TestUserCreate:
    def test_create_with_valid_data(self):
        result = User.create(
            email="test@example.com",
            name="Test",
        )

        assert result.is_success is True
        user = result.value
        assert isinstance(user, User)

    def test_fail_with_invalid_email(self):
        result = User.create(
            email="invalid",
            name="Test",
        )

        assert result.is_failure is True
        assert "email" in result.error.lower()
```

### Testing Result Pattern (Backend — pytest)

```python
import pytest
from unittest.mock import AsyncMock, MagicMock

@pytest.fixture
def mock_repository():
    repo = MagicMock()
    repo.find_by_id = AsyncMock()
    repo.save = AsyncMock()
    return repo

@pytest.fixture
def use_case(mock_repository):
    return ChangeEmailUseCase(repository=mock_repository)

class TestChangeEmailUseCase:
    async def test_change_email_successfully(self, use_case, mock_repository):
        user = User.create(email="old@example.com", name="Test").value
        mock_repository.find_by_id.return_value = user
        mock_repository.save.return_value = None

        result = await use_case.execute(
            user_id=user.id,
            new_email="new@example.com",
        )

        assert result.is_success is True
        mock_repository.save.assert_called_once()
        saved_user = mock_repository.save.call_args[0][0]
        assert saved_user.email.value == "new@example.com"

    async def test_fail_with_invalid_email(self, use_case, mock_repository):
        user = User.create(email="old@example.com", name="Test").value
        mock_repository.find_by_id.return_value = user

        result = await use_case.execute(
            user_id=user.id,
            new_email="invalid",
        )

        assert result.is_failure is True
        mock_repository.save.assert_not_called()
```

### Testing Value Objects (Backend — pytest)

```python
class TestEmail:
    def test_create_valid_email(self):
        result = Email.create("test@example.com")

        assert result.is_success is True
        assert result.value.value == "test@example.com"

    def test_normalize_email(self):
        result = Email.create("  TEST@EXAMPLE.COM  ")

        assert result.is_success is True
        assert result.value.value == "test@example.com"

    def test_validate_format(self):
        result = Email.create("invalid")
        assert result.is_failure is True

    def test_compare_emails(self):
        email1 = Email.create("test@example.com").value
        email2 = Email.create("test@example.com").value
        email3 = Email.create("other@example.com").value

        assert email1 == email2
        assert email1 != email3
```

---

## Test Isolation (Backend — pytest fixtures)

```python
import pytest
from unittest.mock import AsyncMock, MagicMock

@pytest.fixture(autouse=True)
def mock_repository():
    """Fresh mocks for each test — autouse ensures isolation."""
    return MagicMock(
        save=AsyncMock(),
        find_by_id=AsyncMock(),
        find_all=AsyncMock(),
        delete=AsyncMock(),
    )

@pytest.fixture
def service(mock_repository):
    return ProjectService(repository=mock_repository)

class TestProjectService:
    async def test_1(self, service, mock_repository):
        # This test won't affect test_2 — fresh mocks each time
        pass

    async def test_2(self, service, mock_repository):
        # Clean mocks from test_1 via autouse fixture
        pass
```

---

## Integration Testing (Backend — FastAPI TestClient + SQLAlchemy)

```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.session import get_db
from app.db.base import Base

SQLALCHEMY_TEST_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_TEST_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db_session():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()

@pytest.fixture
def client(db_session):
    def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()

class TestProjectIntegration:
    def test_create_project_via_api(self, client, db_session):
        response = client.post(
            "/api/v1/projects",
            json={"name": "Test Project", "description": "Test"},
        )

        assert response.status_code == 201
        project = response.json()["data"]
        assert project["name"] == "Test Project"
        assert project["description"] == "Test"

        # Verify persistence
        from app.models.project import ProjectModel
        saved = db_session.query(ProjectModel).filter_by(id=project["id"]).first()
        assert saved is not None
```

---

## E2E Testing (Playwright) — Frontend

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

### Backend (pytest)

```python
# Good - describes behavior
def test_should_return_error_when_email_is_invalid(): ...
def test_should_create_user_with_valid_data(): ...
def test_should_prevent_duplicate_emails(): ...

# Bad - describes implementation
def test_should_call_validator_validate(): ...
def test_should_set_email_property(): ...
```

### Frontend (Vitest)

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

**Version**: 2.0
**Last Updated**: 2026-04-11
