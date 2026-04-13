# FastAPI Testing Patterns

**Version**: 1.0
**Used by**: Agents 13, 14
**Stack**: fastapi

---

## Test Structure

```
tests/
  conftest.py           # Shared fixtures (client, db, factories)
  unit/
    test_entities.py    # Domain entity tests
    test_use_cases.py   # Use case tests (mocked repos)
  integration/
    test_api_users.py   # API endpoint tests (real DB)
    test_repositories.py # Repository tests (real DB)
  factories.py          # Test data factories
```

---

## TestClient Setup

```python
import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app
from app.dependencies import get_db


@pytest.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac
    app.dependency_overrides.clear()
```

---

## Database Fixtures

```python
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"


@pytest.fixture(scope="session")
def engine():
    return create_async_engine(TEST_DATABASE_URL)


@pytest.fixture
async def db_session(engine):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session
        await session.rollback()

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

---

## Unit Test (Use Case)

```python
from unittest.mock import AsyncMock

import pytest
from app.application.use_cases.create_user import CreateUserUseCase
from app.application.dtos import CreateUserRequest


@pytest.mark.asyncio
async def test_create_user_success():
    # Arrange
    repo = AsyncMock()
    repo.find_by_email.return_value = None
    repo.save.return_value = User(id="1", name="Ana", email="ana@test.com")

    use_case = CreateUserUseCase(repo)
    request = CreateUserRequest(name="Ana", email="ana@test.com")

    # Act
    result = await use_case.execute(request)

    # Assert
    assert result.is_ok
    assert result.value.name == "Ana"
    repo.save.assert_called_once()
```

---

## Integration Test (API)

```python
import pytest


@pytest.mark.asyncio
async def test_create_user_endpoint(client):
    # Act
    response = await client.post("/api/v1/users/", json={
        "name": "Ana",
        "email": "ana@test.com",
    })

    # Assert
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Ana"
    assert "id" in data


@pytest.mark.asyncio
async def test_create_user_duplicate_email(client):
    await client.post("/api/v1/users/", json={"name": "A", "email": "a@t.com"})
    response = await client.post("/api/v1/users/", json={"name": "B", "email": "a@t.com"})
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_get_user_not_found(client):
    response = await client.get("/api/v1/users/nonexistent")
    assert response.status_code == 404
```

---

## Pytest Configuration

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
markers = [
    "unit: Unit tests (no I/O)",
    "integration: Integration tests (database, API)",
]
```

---

## Coverage

```bash
python -m pytest tests/ --cov=app --cov-report=term-missing --cov-fail-under=80
```
