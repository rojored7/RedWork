# DDD/Clean Architecture Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agents 02, 05, 11, 13, 14
**Purpose**: Centralized authority on Domain-Driven Design and Clean Architecture implementation patterns

---

## Overview

This skill document provides **complete, authoritative guidance** on implementing Domain-Driven Design (DDD) and Clean Architecture patterns in Python backends (specifically FastAPI with SQLAlchemy 2.0 async and Pydantic v2).

**Core Philosophy**: Domain logic should be pure, independent of infrastructure, and expressed using rich domain models with strong invariants.

---

## When to Use These Patterns

Use DDD/Clean Architecture when:
- Domain logic is complex and central to business value
- System needs to evolve independently of infrastructure changes
- Multiple teams work on same codebase (bounded contexts provide boundaries)
- Long-term maintainability is critical
- Business rules must be testable in isolation

**Do NOT use when**:
- Simple CRUD with minimal business logic
- Prototype/MVP where speed > structure
- Very small applications (<1000 LOC)

---

## Core DDD Concepts

### 1. Entities

**Definition**: Objects with a unique identity that persists over time, even as their attributes change.

**Key Characteristics**:
- Has a unique identifier (ID)
- Identity remains constant
- Attributes can change
- Two entities with same ID are the same entity
- Encapsulates business logic and invariants

**Python Pattern**:
```python
from __future__ import annotations

from dataclasses import dataclass, field
from uuid import UUID, uuid4

from app.common.core.result import Result
from app.modules.user.domain.value_objects.email import Email


@dataclass
class User:
    # Use a "private" naming convention; constructor is treated as internal.
    # Always create instances through the create()/reconstitute() factories.
    _id: UUID
    _email: Email
    _name: str
    _is_active: bool

    # Factory method for NEW entities
    @classmethod
    def create(cls, *, email: str, name: str) -> Result["User"]:
        email_result = Email.create(email)
        if email_result.is_failure:
            return Result.fail(email_result.error)

        if not name or len(name.strip()) < 2:
            return Result.fail("Name must be at least 2 characters")

        user = cls(
            _id=uuid4(),
            _email=email_result.get_value(),
            _name=name.strip(),
            _is_active=True,  # Default for new users
        )
        return Result.ok(user)

    # Factory method for EXISTING entities (from persistence)
    @classmethod
    def reconstitute(
        cls,
        *,
        id: UUID,
        email: str,
        name: str,
        is_active: bool,
    ) -> Result["User"]:
        email_result = Email.create(email)
        if email_result.is_failure:
            return Result.fail(email_result.error)

        user = cls(
            _id=id,
            _email=email_result.get_value(),
            _name=name,
            _is_active=is_active,
        )
        return Result.ok(user)

    # Read-only properties (no setters - use domain methods)
    @property
    def id(self) -> UUID:
        return self._id

    @property
    def email(self) -> Email:
        return self._email

    @property
    def name(self) -> str:
        return self._name

    @property
    def is_active(self) -> bool:
        return self._is_active

    # Domain methods (business logic)
    def change_email(self, new_email: str) -> Result[None]:
        email_result = Email.create(new_email)
        if email_result.is_failure:
            return Result.fail(email_result.error)

        self._email = email_result.get_value()
        return Result.ok(None)

    def deactivate(self) -> Result[None]:
        if not self._is_active:
            return Result.fail("User already deactivated")

        self._is_active = False
        return Result.ok(None)

    def activate(self) -> Result[None]:
        if self._is_active:
            return Result.fail("User already active")

        self._is_active = True
        return Result.ok(None)
```

### 2. Value Objects

**Definition**: Objects without identity, defined entirely by their attributes. Two value objects with the same attributes are considered identical.

**Key Characteristics**:
- No unique identifier
- Immutable (once created, cannot be changed)
- Equality based on attributes
- Encapsulates validation logic
- Can be shared across entities

**Python Pattern**:
```python
from __future__ import annotations

import re
from dataclasses import dataclass

from app.common.core.result import Result

_EMAIL_REGEX = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


@dataclass(frozen=True)  # frozen=True makes it immutable + provides __eq__/__hash__
class Email:
    value: str

    # Factory method - ONLY way to create
    @classmethod
    def create(cls, email: str) -> Result["Email"]:
        if not email:
            return Result.fail("Email is required")

        if not _EMAIL_REGEX.match(email):
            return Result.fail("Invalid email format")

        return Result.ok(cls(value=email.strip().lower()))

    def __str__(self) -> str:
        return self.value
```

### 3. Aggregates

**Definition**: Cluster of entities and value objects treated as a single unit for data changes.

**Key Characteristics**:
- Has one root entity (Aggregate Root)
- Enforces consistency boundaries
- External objects can only reference the root
- Transactions should not span multiple aggregates

**Example**:
```python
from __future__ import annotations

from dataclasses import dataclass, field
from uuid import UUID, uuid4

from app.common.core.result import Result
from app.modules.order.domain.value_objects.money import Money
from app.modules.order.domain.value_objects.order_status import OrderStatus


@dataclass
class OrderItem:  # Part of Order aggregate (not a separate aggregate)
    _product_id: UUID
    _quantity: int
    _price: Money
    _subtotal: Money

    @classmethod
    def create(cls, *, product_id: UUID, quantity: int, price: Money) -> Result["OrderItem"]:
        if quantity <= 0:
            return Result.fail("Quantity must be positive")

        subtotal = Money.create(price.amount * quantity, price.currency).get_value()
        return Result.ok(cls(_product_id=product_id, _quantity=quantity, _price=price, _subtotal=subtotal))

    @property
    def subtotal(self) -> Money:
        return self._subtotal


@dataclass
class Order:  # Order is Aggregate Root
    _id: UUID
    _customer_id: UUID
    _items: list[OrderItem] = field(default_factory=list)
    _status: OrderStatus = field(default=None)  # type: ignore[assignment]
    _total: Money = field(default=None)  # type: ignore[assignment]

    @classmethod
    def create(cls, *, customer_id: UUID) -> Result["Order"]:
        order = cls(
            _id=uuid4(),
            _customer_id=customer_id,
            _items=[],
            _status=OrderStatus.create("DRAFT").get_value(),
            _total=Money.create(0, "USD").get_value(),
        )
        return Result.ok(order)

    # Domain method - modifies aggregate
    def add_item(self, *, product_id: UUID, quantity: int, price: Money) -> Result[None]:
        if self._status.value != "DRAFT":
            return Result.fail("Cannot add items to non-draft order")

        item_result = OrderItem.create(product_id=product_id, quantity=quantity, price=price)
        if item_result.is_failure:
            return Result.fail(item_result.error)

        self._items.append(item_result.get_value())
        self._recalculate_total()
        return Result.ok(None)

    # Private method - enforces invariants
    def _recalculate_total(self) -> None:
        total_amount = sum(item.subtotal.amount for item in self._items)
        self._total = Money.create(total_amount, "USD").get_value()

    # Domain method - state transition
    def submit(self) -> Result[None]:
        if self._status.value != "DRAFT":
            return Result.fail("Order already submitted")

        if not self._items:
            return Result.fail("Cannot submit empty order")

        self._status = OrderStatus.create("SUBMITTED").get_value()
        return Result.ok(None)
```

---

## Result<T> Pattern

**Purpose**: Handle errors without exceptions, making error paths explicit and type-safe.

**Implementation**:
```python
from __future__ import annotations

from typing import Generic, Optional, TypeVar

T = TypeVar("T")


class Result(Generic[T]):
    def __init__(self, is_success: bool, error: Optional[str] = None, value: Optional[T] = None) -> None:
        if is_success and error:
            raise ValueError("InvalidOperation: A result cannot be successful and contain an error")
        if not is_success and not error:
            raise ValueError("InvalidOperation: A failing result needs an error message")

        self._is_success = is_success
        self._error = error
        self._value = value

    @property
    def is_success(self) -> bool:
        return self._is_success

    @property
    def is_failure(self) -> bool:
        return not self._is_success

    @classmethod
    def ok(cls, value: Optional[T] = None) -> "Result[T]":
        return cls(True, None, value)

    @classmethod
    def fail(cls, error: str) -> "Result[T]":
        return cls(False, error)

    def get_value(self) -> T:
        if not self._is_success:
            raise RuntimeError("Cannot get value from failed result")
        return self._value  # type: ignore[return-value]

    @property
    def error(self) -> str:
        if self._is_success:
            raise RuntimeError("Cannot get error from successful result")
        return self._error  # type: ignore[return-value]
```

**Usage**:
```python
from fastapi import HTTPException, status

# Creating entities
user_result = User.create(email="john@example.com", name="John")

if user_result.is_failure:
    # Handle error
    print(user_result.error)
    return

user = user_result.get_value()

# Domain operations
email_change_result = user.change_email("jane@example.com")

if email_change_result.is_failure:
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=email_change_result.error,
    )
```

---

## Clean Architecture Layers

### Layer Structure

```
┌─────────────────────────────────────┐
│          API/Presentation           │  Routers, Schemas, Dependencies
│       (FastAPI-specific layer)      │
└─────────────────────────────────────┘
              ↓ depends on
┌─────────────────────────────────────┐
│          Application Layer          │  Use cases, Application Services
│    (orchestrates domain logic)     │
└─────────────────────────────────────┘
              ↓ depends on
┌─────────────────────────────────────┐
│           Domain Layer              │  Entities, Value Objects, Domain Services
│    (pure business logic, no I/O)   │  Aggregates, Domain Events
└─────────────────────────────────────┘
              ↑ implemented by
┌─────────────────────────────────────┐
│       Infrastructure Layer          │  Repository implementations, ORM entities
│  (persistence, external services)  │  Mappers, External API clients
└─────────────────────────────────────┘
```

### Layer Rules

1. **Domain Layer** (Innermost):
   - NO dependencies on outer layers
   - NO framework dependencies
   - NO I/O operations (no DB, no HTTP, no file system)
   - Pure Python classes (dataclasses, plain classes)
   - Contains: Entities, Value Objects, Domain Services, Aggregates

2. **Application Layer**:
   - Depends on Domain Layer
   - NO dependencies on Infrastructure or API layers
   - Orchestrates domain objects
   - Defines interfaces for repositories (ports) using `abc.ABC` or `typing.Protocol`
   - Contains: Use Cases, Application Services, DTOs

3. **Infrastructure Layer**:
   - Depends on Domain and Application layers
   - Implements repository interfaces
   - Contains framework-specific code (SQLAlchemy ORM models)
   - Contains: Repository implementations, Mappers, External adapters

4. **API/Presentation Layer** (Outermost):
   - Depends on Application layer
   - Framework-specific (FastAPI routers, Depends)
   - Handles HTTP concerns
   - Contains: Routers, Pydantic schemas, Auth dependencies, Middleware

---

## Repository Pattern

**Purpose**: Abstract persistence logic from domain, allowing domain to remain infrastructure-agnostic.

### Domain Layer: Repository Interface (Port)

```python
# app/modules/user/domain/repositories/user_repository.py
from abc import ABC, abstractmethod
from uuid import UUID

from app.modules.user.domain.entities.user import User
from app.modules.user.domain.value_objects.email import Email


class IUserRepository(ABC):
    @abstractmethod
    async def save(self, user: User) -> None: ...

    @abstractmethod
    async def find_by_id(self, user_id: UUID) -> User | None: ...

    @abstractmethod
    async def find_by_email(self, email: Email) -> User | None: ...

    @abstractmethod
    async def find_all(self) -> list[User]: ...

    @abstractmethod
    async def delete(self, user_id: UUID) -> None: ...
```

### Infrastructure Layer: Repository Implementation (Adapter)

```python
# app/modules/user/infrastructure/persistence/sqlalchemy_user_repository.py
from uuid import UUID

from fastapi import Depends
from sqlalchemy import delete as sa_delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.modules.user.domain.entities.user import User
from app.modules.user.domain.repositories.user_repository import IUserRepository
from app.modules.user.domain.value_objects.email import Email
from app.modules.user.infrastructure.persistence.models import UserModel  # SQLAlchemy model
from app.modules.user.infrastructure.persistence.mappers.user_mapper import UserMapper


class SqlAlchemyUserRepository(IUserRepository):
    def __init__(self, session: AsyncSession = Depends(get_db_session)) -> None:
        self._session = session

    async def save(self, user: User) -> None:
        model = UserMapper.to_persistence(user)
        await self._session.merge(model)

    async def find_by_id(self, user_id: UUID) -> User | None:
        stmt = select(UserModel).where(UserModel.id == user_id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        if model is None:
            return None

        user_result = UserMapper.to_domain(model)
        if user_result.is_failure:
            raise RuntimeError(user_result.error)
        return user_result.get_value()

    async def find_by_email(self, email: Email) -> User | None:
        stmt = select(UserModel).where(UserModel.email == email.value)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        if model is None:
            return None

        user_result = UserMapper.to_domain(model)
        if user_result.is_failure:
            raise RuntimeError(user_result.error)
        return user_result.get_value()

    async def find_all(self) -> list[User]:
        result = await self._session.execute(select(UserModel))
        users: list[User] = []
        for model in result.scalars().all():
            user_result = UserMapper.to_domain(model)
            if user_result.is_success:
                users.append(user_result.get_value())
        return users

    async def delete(self, user_id: UUID) -> None:
        await self._session.execute(sa_delete(UserModel).where(UserModel.id == user_id))
```

---

## Mapper Pattern

**Purpose**: Convert between domain entities and ORM/persistence entities without polluting domain with ORM concerns.

```python
# app/modules/user/infrastructure/persistence/mappers/user_mapper.py
from app.common.core.result import Result
from app.modules.user.api.schemas import UserResponseSchema
from app.modules.user.domain.entities.user import User
from app.modules.user.infrastructure.persistence.models import UserModel  # SQLAlchemy model


class UserMapper:
    # Domain to Persistence (ORM model)
    @staticmethod
    def to_persistence(user: User) -> UserModel:
        return UserModel(
            id=user.id,
            email=user.email.value,
            name=user.name,
            is_active=user.is_active,
        )

    # Persistence to Domain
    @staticmethod
    def to_domain(model: UserModel) -> Result[User]:
        return User.reconstitute(
            id=model.id,
            email=model.email,
            name=model.name,
            is_active=model.is_active,
        )

    # Domain to API response (Pydantic schema)
    @staticmethod
    def to_response(user: User) -> UserResponseSchema:
        return UserResponseSchema(
            id=user.id,
            email=user.email.value,
            name=user.name,
            is_active=user.is_active,
        )
```

---

## Anti-Patterns to AVOID

### 1. Public/Unchecked Constructors
```python
# WRONG - allows unvalidated instantiation
class User:
    def __init__(self, email: str, name: str) -> None:
        self.email = email
        self.name = name


# RIGHT - factory method enforces invariants
class User:
    def __init__(self, *, _id, _email, _name) -> None:  # treat as internal
        self._id = _id
        self._email = _email
        self._name = _name

    @classmethod
    def create(cls, *, email: str, name: str) -> "Result[User]":
        ...
```

### 2. Bypassing Factories
```python
# WRONG - bypasses validation
user = User.__new__(User)
user.email = "test@example.com"

# RIGHT - use factory
user_result = User.create(email="test@example.com", name="Test")
user = user_result.get_value()
```

### 3. Throwing Exceptions in Domain
```python
# WRONG - raising exceptions for expected validation failures
class User:
    def change_email(self, email: str) -> None:
        if "@" not in email:
            raise ValueError("Invalid email")  # NO!
        self._email = email


# RIGHT - return Result[T]
class User:
    def change_email(self, email: str) -> Result[None]:
        email_result = Email.create(email)
        if email_result.is_failure:
            return Result.fail(email_result.error)
        self._email = email_result.get_value()
        return Result.ok(None)
```

### 4. Anemic Domain Model
```python
# WRONG - anemic (just data, no behavior)
@dataclass
class User:
    email: str
    name: str


# Business logic in service instead of domain
class UserService:
    def change_email(self, user: User, email: str) -> None:
        # validation logic here - should be in User entity
        ...


# RIGHT - rich domain model
class User:
    def change_email(self, email: str) -> Result[None]:
        # validation + logic here
        ...
```

### 5. Violating Layer Dependencies
```python
# WRONG - domain depends on infrastructure
# app/modules/user/domain/entities/user.py
from sqlalchemy.orm import Mapped, mapped_column  # NO SQLAlchemy in domain!
from app.core.database import Base


class User(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(primary_key=True)


# RIGHT - domain is pure, infrastructure depends on domain
# Domain entity (pure Python)
class User:
    def __init__(self, *, _id, _email) -> None:
        self._id = _id
        self._email = _email


# Infrastructure ORM model (separate file)
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class UserModel(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(primary_key=True)
    email: Mapped[str]
```

---

## Testing DDD Patterns

### Testing Entities with Factory Methods

```python
# tests/modules/user/domain/test_user_entity.py
from app.modules.user.domain.entities.user import User


class TestUserCreate:
    def test_should_create_user_with_valid_data(self):
        result = User.create(email="john@example.com", name="John Doe")

        assert result.is_success
        user = result.get_value()
        assert user.email.value == "john@example.com"
        assert user.name == "John Doe"
        assert user.is_active is True

    def test_should_fail_with_invalid_email(self):
        result = User.create(email="invalid-email", name="John Doe")

        assert result.is_failure
        assert "email" in result.error.lower()


class TestChangeEmail:
    def test_should_change_email_successfully(self):
        user = User.create(email="old@example.com", name="John").get_value()

        result = user.change_email("new@example.com")

        assert result.is_success
        assert user.email.value == "new@example.com"
```

### Testing with Repository Mocks

```python
# tests/modules/user/application/test_register_user_use_case.py
from unittest.mock import AsyncMock

import pytest

from app.modules.user.application.use_cases.register_user import RegisterUserUseCase
from app.modules.user.domain.entities.user import User


@pytest.fixture
def user_repository():
    repo = AsyncMock()
    repo.find_by_email = AsyncMock(return_value=None)
    repo.save = AsyncMock(return_value=None)
    return repo


@pytest.fixture
def use_case(user_repository):
    return RegisterUserUseCase(user_repository=user_repository)


class TestRegisterUserUseCase:
    async def test_should_register_new_user(self, use_case, user_repository):
        result = await use_case.execute(email="john@example.com", name="John Doe")

        assert result.is_success
        user_repository.save.assert_awaited_once()

    async def test_should_fail_if_email_already_exists(self, use_case, user_repository):
        existing_user = User.create(email="john@example.com", name="Existing").get_value()
        user_repository.find_by_email.return_value = existing_user

        result = await use_case.execute(email="john@example.com", name="John Doe")

        assert result.is_failure
        assert "already exists" in result.error
        user_repository.save.assert_not_awaited()
```

---

## Decision Trees

### When to Use Entity vs Value Object?

```
Does it have a unique identity?
├── YES → Entity
│   └── Does it aggregate other objects?
│       ├── YES → Aggregate Root
│       └── NO → Entity
└── NO → Value Object
    └── Is it immutable?
        ├── YES → Value Object ✓
        └── NO → Reconsider design (VOs should be immutable)
```

### When to Create a New Aggregate?

```
Does this object need transactional consistency with others?
├── YES → Part of existing aggregate
└── NO → Potentially new aggregate
    └── Can it be referenced by ID only?
        ├── YES → New aggregate ✓
        └── NO → Part of existing aggregate
```

---

## References

- **Domain-Driven Design** by Eric Evans
- **Implementing Domain-Driven Design** by Vaughn Vernon
- **Clean Architecture** by Robert C. Martin
- **Enterprise Application Architecture** by Martin Fowler

---

**Version**: 1.0
**Last Updated**: 2026-04-07
**Maintainer**: Framework Team
