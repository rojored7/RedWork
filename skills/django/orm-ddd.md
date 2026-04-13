# Django ORM + DDD Integration

**Version**: 1.0
**Used by**: Agents 02, 05, 10, 14
**Stack**: django

---

## The Challenge

Django's Active Record pattern (Model = Entity + Persistence) conflicts with DDD's
separation of domain from infrastructure. This skill shows how to bridge them.

---

## Repository Pattern over QuerySets

```python
# domain/repositories.py (abstract)
from typing import Protocol


class UserRepository(Protocol):
    def find_by_id(self, user_id: str) -> User | None: ...
    def find_by_email(self, email: str) -> User | None: ...
    def save(self, user: User) -> User: ...
    def exists_by_email(self, email: str) -> bool: ...


# infrastructure/repositories.py (implementation)
from apps.users.models import UserModel


class DjangoUserRepository:
    def find_by_id(self, user_id: str) -> User | None:
        try:
            model = UserModel.objects.get(pk=user_id)
            return self._to_domain(model)
        except UserModel.DoesNotExist:
            return None

    def save(self, user: User) -> User:
        model, _ = UserModel.objects.update_or_create(
            pk=user.id,
            defaults={"name": user.name, "email": user.email},
        )
        return self._to_domain(model)

    def exists_by_email(self, email: str) -> bool:
        return UserModel.objects.filter(email=email).exists()

    def _to_domain(self, model: UserModel) -> User:
        return User(id=str(model.pk), name=model.name, email=model.email)
```

---

## Domain Entity (separate from Model)

```python
# domain/entities.py
from dataclasses import dataclass


@dataclass(frozen=True)
class User:
    id: str
    name: str
    email: str

    def change_email(self, new_email: str) -> "User":
        if not new_email or "@" not in new_email:
            raise DomainError("Invalid email")
        return User(id=self.id, name=self.name, email=new_email)
```

---

## Django Model (persistence only)

```python
# apps/users/models.py
from django.db import models
from apps.core.models import BaseModel


class UserModel(BaseModel):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)

    class Meta:
        db_table = "users"
```

---

## When to Use This Pattern

Use DDD + Repository when:
- Complex business logic that benefits from pure domain objects
- Multiple persistence backends (SQL + cache + external API)
- Domain events needed

Use plain Django Models when:
- CRUD-heavy with minimal business logic
- Small project / prototype
- Team is more comfortable with Django conventions
