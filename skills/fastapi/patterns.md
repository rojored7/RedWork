# FastAPI Patterns

**Version**: 1.0
**Used by**: Agents 10, 13, 14
**Stack**: fastapi

---

## Project Structure

```
app/
  main.py              # FastAPI app, CORS, lifespan
  config.py            # Pydantic Settings
  dependencies.py      # Shared dependencies (get_db, get_current_user)
  domain/
    entities/          # Domain entities (pure Python, no framework deps)
    value_objects/     # Immutable value objects
    repositories/      # Abstract repository interfaces (Protocol)
    services/          # Domain services
  application/
    use_cases/         # Application use cases (orchestration)
    dtos/              # Input/output DTOs (Pydantic models)
  infrastructure/
    persistence/       # SQLAlchemy models, repository implementations
    external/          # External API clients
  api/
    v1/
      routes/          # Route modules grouped by domain
      schemas/         # Request/response Pydantic schemas
    deps.py            # API-specific dependencies
```

---

## Router Organization

```python
from fastapi import APIRouter, Depends, HTTPException, status

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_user(
    payload: CreateUserRequest,
    use_case: CreateUserUseCase = Depends(get_create_user_use_case),
) -> UserResponse:
    result = await use_case.execute(payload)
    if result.is_error:
        raise HTTPException(status_code=400, detail=result.error)
    return UserResponse.from_domain(result.value)
```

---

## Dependency Injection

```python
from functools import lru_cache
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session


def get_user_repository(db: AsyncSession = Depends(get_db)) -> UserRepository:
    return SqlAlchemyUserRepository(db)


def get_create_user_use_case(
    repo: UserRepository = Depends(get_user_repository),
) -> CreateUserUseCase:
    return CreateUserUseCase(repo)
```

---

## Pydantic v2 Models

```python
from pydantic import BaseModel, Field, ConfigDict, field_validator


class CreateUserRequest(BaseModel):
    model_config = ConfigDict(strict=True)

    name: str = Field(min_length=1, max_length=100)
    email: str = Field(pattern=r"^[\w.-]+@[\w.-]+\.\w+$")
    age: int | None = Field(default=None, ge=0, le=150)


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    email: str

    @classmethod
    def from_domain(cls, user: User) -> "UserResponse":
        return cls(id=str(user.id), name=user.name, email=user.email)
```

---

## Settings with Pydantic

```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    model_config = ConfigDict(env_file=".env", env_file_encoding="utf-8")

    database_url: str
    secret_key: str
    debug: bool = False
    cors_origins: list[str] = ["http://localhost:3000"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

---

## Async Patterns

```python
# Correct: use async def for I/O operations
@router.get("/{user_id}")
async def get_user(user_id: str, repo: UserRepository = Depends(get_user_repo)):
    user = await repo.find_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.from_domain(user)


# Correct: use def for CPU-bound (FastAPI runs in threadpool)
@router.post("/hash")
def compute_hash(data: HashRequest):
    return {"hash": hashlib.sha256(data.content.encode()).hexdigest()}
```

---

## Error Handling

```python
from fastapi import Request
from fastapi.responses import JSONResponse


class DomainError(Exception):
    def __init__(self, message: str, code: str = "DOMAIN_ERROR"):
        self.message = message
        self.code = code


@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError):
    return JSONResponse(
        status_code=400,
        content={"error": exc.code, "message": exc.message},
    )
```

---

## Middleware

```python
import time
from fastapi import Request


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start
    response.headers["X-Process-Time"] = str(duration)
    return response
```

---

## Anti-Patterns

- Do NOT put business logic in route handlers (use use cases)
- Do NOT use global mutable state
- Do NOT use `response_model` with complex nested models (use explicit return types)
- Do NOT mix sync and async database calls
- Do NOT hardcode configuration values (use Settings)
