# Configuration Management

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 10 (Backend), Agent 11 (Frontend), Agent 12 (Infrastructure)
**Purpose**: Centralized configuration patterns, environment management, no hardcoded values

---

## Backend Configuration (FastAPI)

### Centralized Configuration with Pydantic Settings

```python
# app/core/config.py
from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppSettings(BaseSettings):
    port: int = 8000
    env: Literal["development", "staging", "production", "test"] = "development"


class DatabaseSettings(BaseSettings):
    host: str = "localhost"
    port: int = 5432
    username: str
    password: SecretStr
    name: str


class JwtSettings(BaseSettings):
    access_secret: SecretStr = Field(..., min_length=32)
    refresh_secret: SecretStr = Field(..., min_length=32)
    access_expiration: str = "15m"
    refresh_expiration: str = "7d"


class RedisSettings(BaseSettings):
    host: str = "localhost"
    port: int = 6379
    password: SecretStr | None = None


class EmailSettings(BaseSettings):
    host: str | None = None
    port: int = 587
    user: str | None = None
    password: SecretStr | None = None
    sender: str | None = None


class CorsSettings(BaseSettings):
    origin: str = "http://localhost:3000"
    credentials: bool = True


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env.local", ".env"),
        env_nested_delimiter="__",
        case_sensitive=False,
        extra="ignore",
    )

    app: AppSettings = AppSettings()
    database: DatabaseSettings
    jwt: JwtSettings
    redis: RedisSettings = RedisSettings()
    email: EmailSettings = EmailSettings()
    cors: CorsSettings = CorsSettings()

    @field_validator("jwt")
    @classmethod
    def validate_jwt_secrets(cls, v: JwtSettings) -> JwtSettings:
        if len(v.access_secret.get_secret_value()) < 32:
            raise ValueError("JWT_ACCESS_SECRET must be at least 32 characters")
        return v


@lru_cache
def get_settings() -> Settings:
    return Settings()


# app/main.py
from fastapi import FastAPI
from app.core.config import get_settings

settings = get_settings()

app = FastAPI(title="Task Manager API")
```

### Using Configuration in Services

```python
from datetime import datetime, timedelta, timezone

from fastapi import Depends
from jose import jwt

from app.core.config import Settings, get_settings


class AuthService:
    def __init__(self, settings: Settings = Depends(get_settings)) -> None:
        self._settings = settings

    def generate_token(self, user_id: str) -> str:
        secret = self._settings.jwt.access_secret.get_secret_value()
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)

        payload = {"sub": user_id, "exp": expires_at}
        return jwt.encode(payload, secret, algorithm="HS256")

    def is_production(self) -> bool:
        return self._settings.app.env == "production"


# NEVER do this
# secret = "hardcoded-secret"  # BAD
```

---

## Frontend Configuration (React)

### Environment-Based Configuration

```typescript
// config/runtime.ts
interface RuntimeConfig {
  apiBaseUrl: string;
  wsBaseUrl: string;
  environment: 'development' | 'staging' | 'production';
  enableAnalytics: boolean;
  logLevel: 'debug' | 'info' | 'warn' | 'error';
}

export const config: RuntimeConfig = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001',
  wsBaseUrl: import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:3001',
  environment: (import.meta.env.VITE_ENVIRONMENT as RuntimeConfig['environment']) || 'development',
  enableAnalytics: import.meta.env.VITE_ENABLE_ANALYTICS === 'true',
  logLevel: (import.meta.env.VITE_LOG_LEVEL as RuntimeConfig['logLevel']) || 'info',
};

// Validation
function validateConfig(config: RuntimeConfig): void {
  if (!config.apiBaseUrl) {
    throw new Error('VITE_API_BASE_URL is required');
  }
  if (!['development', 'staging', 'production'].includes(config.environment)) {
    throw new Error('Invalid VITE_ENVIRONMENT value');
  }
}

validateConfig(config);
```

### Environment Files

```bash
# .env.development
VITE_API_BASE_URL=http://localhost:3001
VITE_WS_BASE_URL=ws://localhost:3001
VITE_ENVIRONMENT=development
VITE_ENABLE_ANALYTICS=false
VITE_LOG_LEVEL=debug

# .env.staging
VITE_API_BASE_URL=https://api-staging.example.com
VITE_WS_BASE_URL=wss://ws-staging.example.com
VITE_ENVIRONMENT=staging
VITE_ENABLE_ANALYTICS=true
VITE_LOG_LEVEL=info

# .env.production
VITE_API_BASE_URL=https://api.example.com
VITE_WS_BASE_URL=wss://ws.example.com
VITE_ENVIRONMENT=production
VITE_ENABLE_ANALYTICS=true
VITE_LOG_LEVEL=warn
```

### Using Configuration

```typescript
// services/api.ts
import { config } from '@/config/runtime';

const api = axios.create({
  baseURL: config.apiBaseUrl, // GOOD - From config
  timeout: 10000,
});

// BAD - Hardcoded
// const api = axios.create({
//   baseURL: 'http://localhost:3001', // NEVER hardcode
// });

// utils/logger.ts
import { config } from '@/config/runtime';

export function log(level: string, message: string): void {
  const levels = ['debug', 'info', 'warn', 'error'];
  const configLevelIndex = levels.indexOf(config.logLevel);
  const messageLevelIndex = levels.indexOf(level);

  if (messageLevelIndex >= configLevelIndex) {
    console[level](message);
  }
}
```

---

## Feature Flags

### Backend Feature Flags

```python
# app/core/features.py
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class FeatureFlags(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="FEATURE_", env_file=".env")

    enable_new_dashboard: bool = False
    enable_email_notifications: bool = False
    enable_file_upload: bool = False
    max_upload_size: int = 5 * 1024 * 1024  # 5MB default


@lru_cache
def get_feature_flags() -> FeatureFlags:
    return FeatureFlags()


# Usage in service
from fastapi import Depends
import logging

logger = logging.getLogger(__name__)


class NotificationService:
    def __init__(self, flags: FeatureFlags = Depends(get_feature_flags)) -> None:
        self._flags = flags

    async def send_email(self, to: str, subject: str, body: str) -> None:
        if not self._flags.enable_email_notifications:
            logger.info("Email notifications disabled, skipping")
            return

        await self._email_client.send(to, subject, body)
```

### Frontend Feature Flags

```typescript
// config/features.ts
export const features = {
  enableNewUI: import.meta.env.VITE_FEATURE_NEW_UI === 'true',
  enableDarkMode: import.meta.env.VITE_FEATURE_DARK_MODE === 'true',
  enableBetaFeatures: import.meta.env.VITE_FEATURE_BETA === 'true',
};

// Usage in component
function Dashboard() {
  if (features.enableNewUI) {
    return <NewDashboard />;
  }
  return <LegacyDashboard />;
}

// Higher-order component for feature flags
function withFeatureFlag(
  Component: React.ComponentType,
  featureName: keyof typeof features,
  FallbackComponent?: React.ComponentType
) {
  return function FeatureFlaggedComponent(props: any) {
    if (features[featureName]) {
      return <Component {...props} />;
    }
    if (FallbackComponent) {
      return <FallbackComponent {...props} />;
    }
    return null;
  };
}

// Usage
const BetaDashboard = withFeatureFlag(NewDashboard, 'enableBetaFeatures', LegacyDashboard);
```

---

## Database Configuration

### SQLAlchemy 2.0 Async Configuration

```python
# app/core/database.py
from functools import lru_cache
from typing import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import Settings, get_settings


def build_database_url(settings: Settings) -> str:
    db = settings.database
    password = db.password.get_secret_value()
    return f"postgresql+asyncpg://{db.username}:{password}@{db.host}:{db.port}/{db.name}"


@lru_cache
def get_engine() -> AsyncEngine:
    settings = get_settings()
    return create_async_engine(
        build_database_url(settings),
        echo=settings.app.env == "development",
        pool_pre_ping=True,
        connect_args={"ssl": True} if settings.app.env == "production" else {},
    )


@lru_cache
def get_session_factory() -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(bind=get_engine(), expire_on_commit=False)


async def get_db_session() -> AsyncIterator[AsyncSession]:
    session_factory = get_session_factory()
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

---

## Infrastructure Configuration

### Docker Compose with Environment Variables

```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "${BACKEND_PORT:-3001}:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - DATABASE_USERNAME=${POSTGRES_USER}
      - DATABASE_PASSWORD=${POSTGRES_PASSWORD}
      - DATABASE_NAME=${POSTGRES_DB}
      - JWT_ACCESS_SECRET=${JWT_ACCESS_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}

volumes:
  postgres_data:
```

### .env for Docker Compose

```bash
# .env
NODE_ENV=development
BACKEND_PORT=3001
POSTGRES_USER=taskmanager
POSTGRES_PASSWORD=secret123
POSTGRES_DB=taskmanager_db
JWT_ACCESS_SECRET=your-super-secret-access-key-min-32-chars
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-chars
REDIS_PASSWORD=redis-secret
```

---

## Secret Management

### Using Secret Management Services

```python
# AWS Secrets Manager example
import os

import boto3


def get_secret(secret_name: str) -> str:
    client = boto3.client("secretsmanager", region_name=os.environ.get("AWS_REGION"))
    response = client.get_secret_value(SecretId=secret_name)
    return response.get("SecretString", "")


# Usage during app startup
from contextlib import asynccontextmanager
from fastapi import FastAPI


@asynccontextmanager
async def lifespan(app: FastAPI):
    if os.environ.get("APP_ENV") == "production":
        os.environ["JWT__ACCESS_SECRET"] = get_secret("prod/jwt-access-secret")
    yield


app = FastAPI(lifespan=lifespan)
```

### Vault Integration

```python
import os

import hvac


def load_secrets_from_vault() -> None:
    client = hvac.Client(
        url=os.environ["VAULT_ADDR"],
        token=os.environ["VAULT_TOKEN"],
    )

    response = client.secrets.kv.v2.read_secret_version(path="taskmanager")
    data = response["data"]["data"]

    os.environ["DATABASE__PASSWORD"] = data["database_password"]
    os.environ["JWT__ACCESS_SECRET"] = data["jwt_access_secret"]
    os.environ["JWT__REFRESH_SECRET"] = data["jwt_refresh_secret"]
```

---

## Configuration Validation

### Pydantic Settings Validation

```python
from typing import Literal

from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppConfig(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False, extra="ignore")

    node_env: Literal["development", "staging", "production", "test"] = "development"
    port: int = 8000

    database_host: str
    database_port: int = 5432
    database_username: str
    database_password: SecretStr
    database_name: str

    jwt_access_secret: SecretStr = Field(..., min_length=32)
    jwt_refresh_secret: SecretStr = Field(..., min_length=32)
    jwt_access_expiration: str = "15m"
    jwt_refresh_expiration: str = "7d"

    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_password: SecretStr | None = None

    cors_origin: str = "http://localhost:3000"

    @model_validator(mode="after")
    def require_redis_password_in_production(self) -> "AppConfig":
        if self.node_env == "production" and not self.redis_password:
            raise ValueError("REDIS_PASSWORD is required in production")
        return self


# Validate on startup - Pydantic raises ValidationError with full details
try:
    config = AppConfig()
except Exception as exc:
    raise RuntimeError(f"Config validation error: {exc}") from exc
```

---

## Runtime Configuration Updates

### Hot Reload Configuration

```python
import json
import logging
from pathlib import Path
from threading import Lock

from watchfiles import watch

logger = logging.getLogger(__name__)


class ConfigManager:
    def __init__(self, config_path: Path) -> None:
        self._config_path = config_path
        self._lock = Lock()
        self._config: dict = {}
        self._load_config()

    def _load_config(self) -> None:
        with self._lock:
            self._config = json.loads(self._config_path.read_text(encoding="utf-8"))
        logger.info("Configuration loaded")

    def watch_forever(self) -> None:
        for _ in watch(self._config_path):
            try:
                self._load_config()
                logger.info("Configuration reloaded")
            except Exception as exc:
                logger.error("Failed to reload config: %s", exc)

    def get(self, key: str, default=None):
        with self._lock:
            return self._config.get(key, default)


config_manager = ConfigManager(Path(__file__).parent / "config.json")
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
