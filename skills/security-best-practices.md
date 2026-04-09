# Security Best Practices

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 19 (Security Review), Agent 10 (Backend)
**Purpose**: Comprehensive security patterns and OWASP Top 10 mitigations

---

## Input Validation

### Backend Validation (FastAPI)

```python
import re
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


PASSWORD_PATTERN = re.compile(
    r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$"
)
NAME_PATTERN = re.compile(r"^[a-zA-Z\s'-]+$")


class CreateUserDto(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    email: Annotated[EmailStr, Field(max_length=255)]
    password: Annotated[str, Field(min_length=8, max_length=128)]
    name: Annotated[str, Field(min_length=2, max_length=100)]

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not PASSWORD_PATTERN.match(v):
            raise ValueError(
                "Password must include uppercase, lowercase, number, and special character"
            )
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        if not NAME_PATTERN.match(v):
            raise ValueError("Name contains invalid characters")
        return v


router = APIRouter()


@router.post("/register")
async def register(dto: CreateUserDto, auth_service=Depends()):
    # Pydantic already rejects unknown fields (extra="forbid") and validates input
    return await auth_service.register(dto)
```

### Frontend Validation

```typescript
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Invalid email').max(255),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(128)
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
      'Password must include uppercase, lowercase, number, and special character'
    ),
});

// Usage in form
const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(loginSchema),
});
```

---

## Authentication & Authorization

### JWT Best Practices

```python
# Generate secure tokens with python-jose
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from jose import JWTError, jwt

from app.core.config import Settings, get_settings


class AuthService:
    def __init__(self, settings: Settings = Depends(get_settings)) -> None:
        self._settings = settings

    def generate_tokens(self, user_id: str) -> dict:
        now = datetime.now(timezone.utc)

        access_token = jwt.encode(
            {"sub": user_id, "exp": now + timedelta(minutes=15)},  # Short-lived
            self._settings.jwt.access_secret.get_secret_value(),
            algorithm="HS256",
        )
        refresh_token = jwt.encode(
            {"sub": user_id, "exp": now + timedelta(days=7)},
            self._settings.jwt.refresh_secret.get_secret_value(),
            algorithm="HS256",
        )
        return {"access_token": access_token, "refresh_token": refresh_token}

    async def refresh_access_token(self, refresh_token: str, blacklist) -> dict:
        try:
            payload = jwt.decode(
                refresh_token,
                self._settings.jwt.refresh_secret.get_secret_value(),
                algorithms=["HS256"],
            )
        except JWTError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
            ) from exc

        if await blacklist.is_blacklisted(refresh_token):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has been revoked",
            )

        return self.generate_tokens(payload["sub"])
```

### Secure Password Hashing

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=12)


class PasswordService:
    def hash(self, plain_password: str) -> str:
        return pwd_context.hash(plain_password)

    def verify(self, plain_password: str, hashed_password: str) -> bool:
        return pwd_context.verify(plain_password, hashed_password)


# NEVER store passwords in plain text
# NEVER use weak hashing (MD5, SHA1)
# ALWAYS use bcrypt, argon2, or scrypt (passlib supports all of them)
```

### Authorization Dependencies

```python
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.modules.auth.dependencies import get_current_user
from app.modules.project.repositories import ProjectRepository


async def require_project_ownership(
    project_id: UUID,
    current_user=Depends(get_current_user),
    project_repo: ProjectRepository = Depends(),
):
    project = await project_repo.find_by_id(project_id)

    if project is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Project not found",
        )

    if project.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not own this resource",
        )

    return project


router = APIRouter()


@router.delete("/projects/{project_id}")
async def delete_project(
    project_id: UUID,
    project=Depends(require_project_ownership),
    project_service=Depends(),
):
    return await project_service.delete(project_id)
```

---

## XSS Prevention

### Backend Response Sanitization

```python
import bleach


class SanitizationService:
    def sanitize_user_input(self, value: str) -> str:
        # No HTML allowed
        return bleach.clean(value, tags=[], attributes={}, strip=True)

    def sanitize_rich_text(self, value: str) -> str:
        return bleach.clean(
            value,
            tags=["b", "i", "em", "strong", "a", "p", "ul", "li"],
            attributes={"a": ["href"]},
            protocols=["http", "https", "mailto"],
            strip=True,
        )
```

### Frontend XSS Protection

```typescript
// BAD - Dangerous innerHTML
function UserComment({ comment }: { comment: string }) {
  return <div dangerouslySetInnerHTML={{ __html: comment }} />;
}

// GOOD - React auto-escapes
function UserComment({ comment }: { comment: string }) {
  return <div>{comment}</div>;
}

// GOOD - Sanitize if HTML is needed
import DOMPurify from 'dompurify';

function RichComment({ comment }: { comment: string }) {
  const sanitized = DOMPurify.sanitize(comment);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

---

## CSRF Prevention

### Backend CSRF Protection

```python
# Using starlette-csrf middleware with FastAPI
from fastapi import APIRouter, Depends, FastAPI, Request
from starlette_csrf import CSRFMiddleware

from app.core.config import get_settings

settings = get_settings()

app = FastAPI()
app.add_middleware(
    CSRFMiddleware,
    secret=settings.jwt.access_secret.get_secret_value(),
    cookie_name="csrftoken",
    header_name="x-csrf-token",
    exempt_urls=[r"^/api/public/"],
)


router = APIRouter()


@router.get("/csrf-token")
async def get_csrf_token(request: Request) -> dict:
    # starlette-csrf sets the cookie automatically; expose it for SPAs if needed
    return {"csrf_token": request.cookies.get("csrftoken")}


@router.post("/transfer")
async def transfer(dto: "TransferDto", transfer_service=Depends()):
    # CSRF enforcement happens in middleware before reaching the handler
    return await transfer_service.execute(dto)
```

### Frontend CSRF Handling

```typescript
// Fetch CSRF token on app load
useEffect(() => {
  async function fetchCsrfToken() {
    const response = await fetch('/api/csrf-token');
    const { csrfToken } = await response.json();
    localStorage.setItem('csrfToken', csrfToken);
  }
  fetchCsrfToken();
}, []);

// Include CSRF token in requests
async function submitForm(data: FormData) {
  const csrfToken = localStorage.getItem('csrfToken');

  await fetch('/api/transfer', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
    },
    body: JSON.stringify(data),
  });
}
```

---

## SQL Injection Prevention

### Use ORMs with Parameterization

```python
# GOOD - SQLAlchemy 2.0 async parameterized query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.user.models import User


async def find_user_by_email(session: AsyncSession, email: str) -> User | None:
    stmt = select(User).where(User.email == email)  # Parameterized
    result = await session.execute(stmt)
    return result.scalar_one_or_none()


# GOOD - LIKE with bound parameters
async def search_users(session: AsyncSession, search_term: str) -> list[User]:
    stmt = select(User).where(User.name.ilike(f"%{search_term}%"))  # Bound parameter
    result = await session.execute(stmt)
    return list(result.scalars().all())


# BAD - String interpolation into raw SQL (SQL injection)
async def search_users_bad(session: AsyncSession, search_term: str):
    raw = f"SELECT * FROM users WHERE name LIKE '%{search_term}%'"  # VULNERABLE
    return await session.execute(raw)
```

---

## Secrets Management

### Environment Variables

```bash
# .env (NEVER commit to git)
JWT__ACCESS_SECRET=your-super-secret-key-min-32-chars
JWT__REFRESH_SECRET=another-super-secret-key-min-32-chars
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/db
```

```gitignore
# .gitignore
.env
.env.local
.env.*.local
```

### Centralized Configuration

```python
# app/core/config.py
from functools import lru_cache

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class JwtSettings(BaseSettings):
    access_secret: SecretStr = Field(..., min_length=32)
    refresh_secret: SecretStr = Field(..., min_length=32)
    access_expiration: str = "15m"
    refresh_expiration: str = "7d"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_nested_delimiter="__")

    jwt: JwtSettings
    database_url: str


@lru_cache
def get_settings() -> Settings:
    return Settings()


# NEVER hardcode secrets
# BAD
secret = "my-secret-key"  # NEVER DO THIS

# GOOD
secret = get_settings().jwt.access_secret.get_secret_value()
```

---

## Rate Limiting

### Backend Rate Limiting

```python
# Rate limiting with slowapi
from fastapi import APIRouter, FastAPI, Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address, default_limits=["10/minute"])

app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)


router = APIRouter()


# Default rate limit (10 requests per minute)
@router.post("/login")
@limiter.limit("10/minute")
async def login(request: Request, dto: "LoginDto", auth_service=Depends()):
    return await auth_service.login(dto)


# Stricter rate limit for sensitive endpoints
@router.post("/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(request: Request, dto: "ForgotPasswordDto", auth_service=Depends()):
    return await auth_service.forgot_password(dto)
```

---

## CORS Configuration

```python
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.environ.get("FRONTEND_URL", "http://localhost:3000")],
    allow_credentials=True,  # Allow cookies
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["Content-Type", "Authorization", "X-CSRF-Token"],
    expose_headers=["X-Total-Count"],
    max_age=3600,  # Cache preflight for 1 hour
)

# NEVER use allow_origins=["*"] in production
```

---

## Security Headers

```python
# Using secure (https://github.com/TypeError/secure) with FastAPI
from fastapi import FastAPI, Request
from fastapi.responses import Response
from secure import Secure

secure_headers = Secure.with_default_headers()

app = FastAPI()


@app.middleware("http")
async def set_secure_headers(request: Request, call_next):
    response: Response = await call_next(request)
    secure_headers.set_headers(response)
    # Customize CSP and HSTS as needed
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; "
        "style-src 'self' 'unsafe-inline'; "
        "script-src 'self'; "
        "img-src 'self' data: https:"
    )
    response.headers["Strict-Transport-Security"] = (
        "max-age=31536000; includeSubDomains; preload"
    )
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers.pop("Server", None)
    return response
```

---

## File Upload Security

```python
import secrets
from pathlib import Path

import magic  # python-magic for content-based MIME detection
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf"}
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "application/pdf"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
UPLOAD_DIR = Path("./uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

router = APIRouter()


@router.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    # 1. Validate extension
    extension = Path(file.filename or "").suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type",
        )

    # 2. Read content with size enforcement
    content = await file.read(MAX_FILE_SIZE + 1)
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File too large",
        )

    # 3. Validate file content (not just extension)
    detected_mime = magic.from_buffer(content, mime=True)
    if detected_mime not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File content does not match extension",
        )

    # 4. Persist with a random, safe filename
    safe_name = f"{secrets.token_urlsafe(16)}{extension}"
    target = UPLOAD_DIR / safe_name
    target.write_bytes(content)

    return {"filename": safe_name}
```

---

## Logging Security Events

```python
import logging
from datetime import datetime, timezone


class SecurityLogger:
    def __init__(self) -> None:
        self._logger = logging.getLogger("security")

    def log_login_attempt(self, email: str, success: bool, ip: str) -> None:
        self._logger.info(
            "LOGIN_ATTEMPT",
            extra={
                "event": "LOGIN_ATTEMPT",
                "email": email,
                "success": success,
                "ip": ip,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )

    def log_password_change(self, user_id: str, ip: str) -> None:
        self._logger.info(
            "PASSWORD_CHANGE",
            extra={
                "event": "PASSWORD_CHANGE",
                "user_id": user_id,
                "ip": ip,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )

    def log_suspicious_activity(self, user_id: str, activity: str, ip: str) -> None:
        self._logger.warning(
            "SUSPICIOUS_ACTIVITY",
            extra={
                "event": "SUSPICIOUS_ACTIVITY",
                "user_id": user_id,
                "activity": activity,
                "ip": ip,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )

    # NEVER log sensitive data
    # BAD: logger.info("login", extra={"password": user.password})
    # GOOD: logger.info("login", extra={"user_id": user.id})
```

---

## Error Handling

```python
# NEVER expose internal errors to clients
import logging

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)
app = FastAPI()


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content={"message": exc.detail})


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    # Log full error internally with traceback
    logger.exception("Unhandled exception", exc_info=exc)

    # Generic error for unknown exceptions
    return JSONResponse(
        status_code=500,
        content={"message": "An error occurred. Please try again later."},
    )


# BAD - Exposes internal details
# raise RuntimeError(f"Database connection failed: {connection_string}")

# GOOD - Generic error
raise HTTPException(status_code=500, detail="Unable to process request")
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
