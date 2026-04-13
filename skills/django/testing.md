# Django Testing Patterns

**Version**: 1.0
**Used by**: Agents 13, 14
**Stack**: django

---

## Test Setup (pytest-django)

```toml
# pyproject.toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings.test"
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
markers = [
    "unit: Unit tests",
    "integration: Integration tests",
]
```

---

## Fixtures

```python
import pytest
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def authenticated_client(api_client, user):
    api_client.force_authenticate(user=user)
    return api_client


@pytest.fixture
def user(db):
    return User.objects.create_user(
        name="Test User",
        email="test@example.com",
        password="TestPass123",
    )
```

---

## Factory Boy

```python
import factory
from apps.users.models import User


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    name = factory.Faker("name")
    email = factory.Sequence(lambda n: f"user{n}@example.com")
    is_active = True

    @factory.post_generation
    def password(self, create, extracted, **kwargs):
        self.set_password(extracted or "DefaultPass123")
        if create:
            self.save()
```

---

## Unit Test (Service)

```python
from unittest.mock import Mock

import pytest
from apps.users.services import UserService


class TestUserService:
    def test_create_user_success(self):
        # Arrange
        repo = Mock()
        repo.exists_by_email.return_value = False
        repo.save.side_effect = lambda u: u
        service = UserService(repo)

        # Act
        user = service.create_user("Ana", "ana@test.com", "Pass1234")

        # Assert
        assert user.name == "Ana"
        repo.save.assert_called_once()

    def test_create_user_duplicate_email_raises(self):
        repo = Mock()
        repo.exists_by_email.return_value = True
        service = UserService(repo)

        with pytest.raises(DomainError, match="already registered"):
            service.create_user("Ana", "ana@test.com", "Pass1234")
```

---

## Integration Test (API)

```python
import pytest


@pytest.mark.django_db
class TestUserAPI:
    def test_create_user(self, api_client):
        response = api_client.post("/api/v1/users/", {
            "name": "Ana",
            "email": "ana@test.com",
            "password": "TestPass123",
        })
        assert response.status_code == 201
        assert response.data["name"] == "Ana"

    def test_list_users_requires_auth(self, api_client):
        response = api_client.get("/api/v1/users/")
        assert response.status_code == 401

    def test_list_users_authenticated(self, authenticated_client):
        response = authenticated_client.get("/api/v1/users/")
        assert response.status_code == 200
```

---

## Coverage

```bash
python -m pytest --cov=apps --cov-report=term-missing --cov-fail-under=80
```
