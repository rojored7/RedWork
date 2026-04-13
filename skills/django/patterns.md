# Django Patterns

**Version**: 1.0
**Used by**: Agents 10, 13, 14
**Stack**: django

---

## Project Structure

```
project/
  manage.py
  config/
    settings/
      base.py          # Shared settings
      dev.py           # Development overrides
      prod.py          # Production overrides
    urls.py            # Root URL configuration
    wsgi.py
  apps/
    users/
      models.py        # Django ORM models
      views.py         # ViewSets or APIViews
      serializers.py   # DRF serializers
      urls.py          # App-level routes
      services.py      # Business logic (not in views)
      repositories.py  # Data access abstraction
      tests/
        test_models.py
        test_views.py
        test_services.py
    core/
      models.py        # Abstract base models (timestamps, soft delete)
      permissions.py   # Custom permission classes
      pagination.py    # Custom pagination
```

---

## Abstract Base Model

```python
from django.db import models
import uuid


class BaseModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
        ordering = ["-created_at"]
```

---

## Service Layer

```python
# apps/users/services.py
from django.db import transaction


class UserService:
    def __init__(self, user_repo: UserRepository):
        self._repo = user_repo

    @transaction.atomic
    def create_user(self, name: str, email: str, password: str) -> User:
        if self._repo.exists_by_email(email):
            raise DomainError("Email already registered")
        user = User(name=name, email=email)
        user.set_password(password)
        return self._repo.save(user)
```

---

## DRF Serializers

```python
from rest_framework import serializers


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "name", "email", "created_at"]
        read_only_fields = ["id", "created_at"]


class CreateUserSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, write_only=True)

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already in use")
        return value
```

---

## ViewSet

```python
from rest_framework import viewsets, status
from rest_framework.response import Response


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateUserSerializer
        return UserSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = self.service.create_user(**serializer.validated_data)
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)
```

---

## QuerySet Patterns

```python
class UserQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)

    def with_orders(self):
        return self.prefetch_related("orders")


class UserManager(models.Manager):
    def get_queryset(self):
        return UserQuerySet(self.model, using=self._db)

    def active(self):
        return self.get_queryset().active()
```

---

## Anti-Patterns

- Do NOT put business logic in views (use services)
- Do NOT use `Model.objects.all()` without pagination
- Do NOT use `select_related` / `prefetch_related` everywhere (profile first)
- Do NOT override `save()` for side effects (use signals or services)
- Do NOT use raw SQL unless QuerySet ORM is insufficient
