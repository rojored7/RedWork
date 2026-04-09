# OpenAPI Code Generation

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 05c (API-First), Agent 10 (Backend), Agent 11 (Frontend), Agent 15 (Integration Test)
**Purpose**: OpenAPI specification patterns and code generation strategies for backend DTOs and frontend API clients

---

## OpenAPI 3.0 Specification Structure

### Complete Example

```yaml
openapi: 3.0.3
info:
  title: Task Manager API
  version: 1.0.0
  description: RESTful API for task management system
  contact:
    name: API Support
    email: api@taskmanager.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: http://localhost:3001/api/v1
    description: Development server
  - url: https://api.taskmanager.com/v1
    description: Production server

tags:
  - name: tasks
    description: Task operations
  - name: projects
    description: Project operations
  - name: auth
    description: Authentication

security:
  - BearerAuth: []

paths:
  /tasks:
    get:
      summary: List all tasks
      operationId: getTasks
      tags: [tasks]
      parameters:
        - name: projectId
          in: query
          required: false
          schema:
            type: string
            format: uuid
        - name: status
          in: query
          schema:
            type: string
            enum: [TODO, IN_PROGRESS, DONE]
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
        - name: cursor
          in: query
          schema:
            type: string
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedTaskResponse'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '500':
          $ref: '#/components/responses/InternalError'

    post:
      summary: Create a new task
      operationId: createTask
      tags: [tasks]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTaskDTO'
      responses:
        '201':
          description: Task created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TaskDTO'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/UnauthorizedError'
        '500':
          $ref: '#/components/responses/InternalError'

  /tasks/{id}:
    get:
      summary: Get task by ID
      operationId: getTaskById
      tags: [tasks]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Task found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TaskDTO'
        '404':
          $ref: '#/components/responses/NotFoundError'

    put:
      summary: Update task
      operationId: updateTask
      tags: [tasks]
      parameters:
        - $ref: '#/components/parameters/TaskId'
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateTaskDTO'
      responses:
        '200':
          description: Task updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/TaskDTO'

    delete:
      summary: Delete task
      operationId: deleteTask
      tags: [tasks]
      parameters:
        - $ref: '#/components/parameters/TaskId'
      responses:
        '204':
          description: Task deleted successfully
        '404':
          $ref: '#/components/responses/NotFoundError'

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  parameters:
    TaskId:
      name: id
      in: path
      required: true
      schema:
        type: string
        format: uuid

  schemas:
    TaskDTO:
      type: object
      required: [id, title, status, createdAt, updatedAt]
      properties:
        id:
          type: string
          format: uuid
        title:
          type: string
          minLength: 1
          maxLength: 200
        description:
          type: string
          maxLength: 2000
        status:
          type: string
          enum: [TODO, IN_PROGRESS, DONE]
        priority:
          type: string
          enum: [LOW, MEDIUM, HIGH]
        dueDate:
          type: string
          format: date-time
        projectId:
          type: string
          format: uuid
        assigneeId:
          type: string
          format: uuid
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    CreateTaskDTO:
      type: object
      required: [title, projectId]
      properties:
        title:
          type: string
          minLength: 1
          maxLength: 200
        description:
          type: string
          maxLength: 2000
        status:
          type: string
          enum: [TODO, IN_PROGRESS, DONE]
          default: TODO
        priority:
          type: string
          enum: [LOW, MEDIUM, HIGH]
          default: MEDIUM
        dueDate:
          type: string
          format: date-time
        projectId:
          type: string
          format: uuid
        assigneeId:
          type: string
          format: uuid

    UpdateTaskDTO:
      type: object
      properties:
        title:
          type: string
          minLength: 1
          maxLength: 200
        description:
          type: string
          maxLength: 2000
        status:
          type: string
          enum: [TODO, IN_PROGRESS, DONE]
        priority:
          type: string
          enum: [LOW, MEDIUM, HIGH]
        dueDate:
          type: string
          format: date-time
        assigneeId:
          type: string
          format: uuid

    PaginatedTaskResponse:
      type: object
      required: [data, pagination]
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/TaskDTO'
        pagination:
          $ref: '#/components/schemas/PaginationMeta'

    PaginationMeta:
      type: object
      required: [total, limit]
      properties:
        total:
          type: integer
          minimum: 0
        limit:
          type: integer
          minimum: 1
        cursor:
          type: string
        hasMore:
          type: boolean

    ErrorResponse:
      type: object
      required: [error]
      properties:
        error:
          type: object
          required: [code, message, timestamp]
          properties:
            code:
              type: string
              example: RESOURCE_NOT_FOUND
            message:
              type: string
              example: Task with ID 123 not found
            details:
              type: array
              items:
                type: object
            timestamp:
              type: string
              format: date-time
            path:
              type: string
              example: /api/tasks/123

  responses:
    UnauthorizedError:
      description: Authentication required
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error:
              code: UNAUTHORIZED
              message: Authentication token missing or invalid
              timestamp: 2024-01-15T10:30:00Z

    ValidationError:
      description: Validation failed
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
          example:
            error:
              code: VALIDATION_FAILED
              message: Request validation failed
              details:
                - field: title
                  message: Title is required
              timestamp: 2024-01-15T10:30:00Z

    NotFoundError:
      description: Resource not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ErrorResponse'
```

---

## Frontend TypeScript Code Generation

### Tool: openapi-typescript

```bash
# Install
npm install --save-dev openapi-typescript

# Generate types
npx openapi-typescript ./openapi.yaml -o ./src/api/generated/types.ts
```

### Generated TypeScript Types

```typescript
// src/api/generated/types.ts (auto-generated)
export interface paths {
  '/tasks': {
    get: {
      parameters: {
        query: {
          projectId?: string;
          status?: 'TODO' | 'IN_PROGRESS' | 'DONE';
          limit?: number;
          cursor?: string;
        };
      };
      responses: {
        200: {
          content: {
            'application/json': components['schemas']['PaginatedTaskResponse'];
          };
        };
        401: components['responses']['UnauthorizedError'];
        500: components['responses']['InternalError'];
      };
    };
    post: {
      requestBody: {
        content: {
          'application/json': components['schemas']['CreateTaskDTO'];
        };
      };
      responses: {
        201: {
          content: {
            'application/json': components['schemas']['TaskDTO'];
          };
        };
      };
    };
  };
  '/tasks/{id}': {
    get: {
      parameters: {
        path: {
          id: string;
        };
      };
      responses: {
        200: {
          content: {
            'application/json': components['schemas']['TaskDTO'];
          };
        };
      };
    };
  };
}

export interface components {
  schemas: {
    TaskDTO: {
      id: string;
      title: string;
      description?: string;
      status: 'TODO' | 'IN_PROGRESS' | 'DONE';
      priority?: 'LOW' | 'MEDIUM' | 'HIGH';
      dueDate?: string;
      projectId?: string;
      assigneeId?: string;
      createdAt: string;
      updatedAt: string;
    };
    CreateTaskDTO: {
      title: string;
      description?: string;
      status?: 'TODO' | 'IN_PROGRESS' | 'DONE';
      priority?: 'LOW' | 'MEDIUM' | 'HIGH';
      dueDate?: string;
      projectId: string;
      assigneeId?: string;
    };
    UpdateTaskDTO: {
      title?: string;
      description?: string;
      status?: 'TODO' | 'IN_PROGRESS' | 'DONE';
      priority?: 'LOW' | 'MEDIUM' | 'HIGH';
      dueDate?: string;
      assigneeId?: string;
    };
    PaginatedTaskResponse: {
      data: components['schemas']['TaskDTO'][];
      pagination: components['schemas']['PaginationMeta'];
    };
  };
}
```

### Type-Safe API Client Generation

```typescript
// src/api/taskApi.ts
import { get, post, put, del } from '@/services/api';
import type { components } from './generated/types';

type TaskDTO = components['schemas']['TaskDTO'];
type CreateTaskDTO = components['schemas']['CreateTaskDTO'];
type UpdateTaskDTO = components['schemas']['UpdateTaskDTO'];
type PaginatedTaskResponse = components['schemas']['PaginatedTaskResponse'];

export const taskApi = {
  getAll: (params?: {
    projectId?: string;
    status?: 'TODO' | 'IN_PROGRESS' | 'DONE';
    limit?: number;
    cursor?: string;
  }): Promise<PaginatedTaskResponse> => {
    return get('/tasks', params);
  },

  getById: (id: string): Promise<TaskDTO> => {
    return get(`/tasks/${id}`);
  },

  create: (dto: CreateTaskDTO): Promise<TaskDTO> => {
    return post('/tasks', dto);
  },

  update: (id: string, dto: UpdateTaskDTO): Promise<TaskDTO> => {
    return put(`/tasks/${id}`, dto);
  },

  delete: (id: string): Promise<void> => {
    return del(`/tasks/${id}`);
  },
};
```

---

## Backend FastAPI Code Generation

### Manual Pydantic v2 Schema Creation from OpenAPI

```python
# app/modules/task/api/schemas/task_schemas.py
from datetime import datetime
from enum import Enum
from typing import Annotated, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TaskStatus(str, Enum):
    TODO = "TODO"
    IN_PROGRESS = "IN_PROGRESS"
    DONE = "DONE"


class TaskPriority(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class CreateTaskSchema(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    title: Annotated[str, Field(min_length=1, max_length=200)]
    description: Annotated[Optional[str], Field(default=None, max_length=2000)]
    status: TaskStatus = TaskStatus.TODO
    priority: TaskPriority = TaskPriority.MEDIUM
    due_date: Optional[datetime] = None
    project_id: UUID
    assignee_id: Optional[UUID] = None


class UpdateTaskSchema(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    title: Annotated[Optional[str], Field(default=None, min_length=1, max_length=200)]
    description: Annotated[Optional[str], Field(default=None, max_length=2000)]
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    due_date: Optional[datetime] = None
    assignee_id: Optional[UUID] = None


class TaskResponseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    description: Optional[str] = None
    status: TaskStatus
    priority: Optional[TaskPriority] = None
    due_date: Optional[datetime] = None
    project_id: Optional[UUID] = None
    assignee_id: Optional[UUID] = None
    created_at: datetime
    updated_at: datetime
```

### FastAPI Router and OpenAPI Docs Integration

```python
# app/main.py
from fastapi import FastAPI
from fastapi.security import HTTPBearer

from app.modules.task.api.routers import task_router

bearer_scheme = HTTPBearer()

app = FastAPI(
    title="Task Manager API",
    description="RESTful API for task management system",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

app.include_router(task_router.router, prefix="/api/v1", tags=["tasks"])


# app/modules/task/api/routers/task_router.py
from uuid import UUID
from fastapi import APIRouter, Depends, Query, status

from app.modules.task.api.schemas.task_schemas import (
    CreateTaskSchema,
    TaskResponseSchema,
    TaskStatus,
    UpdateTaskSchema,
)
from app.modules.task.application.services import TaskService
from app.modules.auth.dependencies import get_current_user

router = APIRouter(prefix="/tasks")


@router.get("", response_model=list[TaskResponseSchema])
async def list_tasks(
    project_id: UUID | None = Query(default=None),
    status_filter: TaskStatus | None = Query(default=None, alias="status"),
    limit: int = Query(default=20, ge=1, le=100),
    service: TaskService = Depends(),
    current_user=Depends(get_current_user),
):
    return await service.list_tasks(project_id=project_id, status=status_filter, limit=limit)


@router.post("", response_model=TaskResponseSchema, status_code=status.HTTP_201_CREATED)
async def create_task(
    payload: CreateTaskSchema,
    service: TaskService = Depends(),
    current_user=Depends(get_current_user),
):
    return await service.create_task(payload)
```

---

## Mock Server Setup

### Option 1: Prism CLI

```bash
# Install
npm install --save-dev @stoplight/prism-cli

# Run mock server
npx prism mock openapi.yaml

# Server runs at http://localhost:4010
# Automatically generates responses based on examples
```

### Option 2: MSW (Mock Service Worker) for Frontend

```typescript
// src/mocks/handlers.ts
import { rest } from 'msw';
import type { components } from '@/api/generated/types';

type TaskDTO = components['schemas']['TaskDTO'];

const mockTasks: TaskDTO[] = [
  {
    id: '550e8400-e29b-41d4-a716-446655440000',
    title: 'Sample Task',
    status: 'TODO',
    priority: 'MEDIUM',
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2024-01-15T10:00:00Z',
  },
];

export const handlers = [
  rest.get('/api/v1/tasks', (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        data: mockTasks,
        pagination: { total: 1, limit: 20, hasMore: false },
      })
    );
  }),

  rest.post('/api/v1/tasks', async (req, res, ctx) => {
    const body = await req.json();
    const newTask: TaskDTO = {
      id: crypto.randomUUID(),
      ...body,
      status: body.status || 'TODO',
      priority: body.priority || 'MEDIUM',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    mockTasks.push(newTask);
    return res(ctx.status(201), ctx.json(newTask));
  }),
];
```

---

## Contract Testing

### Validate Implementation Against OpenAPI Spec

```python
# tests/contract/test_api_contract.py
import pytest
import yaml
from fastapi.testclient import TestClient
from openapi_core import Spec
from openapi_core.contrib.starlette import StarletteOpenAPIRequest, StarletteOpenAPIResponse
from openapi_core.validation.request import openapi_request_validator
from openapi_core.validation.response import openapi_response_validator

from app.main import app


@pytest.fixture(scope="module")
def spec():
    with open("./openapi.yaml", "r") as f:
        return Spec.from_dict(yaml.safe_load(f))


@pytest.fixture(scope="module")
def client():
    return TestClient(app)


def test_post_tasks_matches_openapi_spec(client, spec):
    response = client.post(
        "/api/v1/tasks",
        json={
            "title": "Test Task",
            "project_id": "550e8400-e29b-41d4-a716-446655440000",
        },
    )

    assert response.status_code == 201
    # openapi-core validates response payload against the spec
    openapi_response_validator.validate(spec, response.request, response)


def test_get_tasks_matches_openapi_spec(client, spec):
    response = client.get("/api/v1/tasks", params={"status": "TODO", "limit": 20})

    assert response.status_code == 200
    openapi_response_validator.validate(spec, response.request, response)
```

---

## API Versioning Patterns

### URL Versioning (Recommended)

```yaml
paths:
  /v1/tasks:
    get:
      # Version 1 implementation
  /v2/tasks:
    get:
      # Version 2 with breaking changes
```

```python
# FastAPI routers per version
from fastapi import APIRouter

tasks_v1 = APIRouter(prefix="/v1/tasks", tags=["tasks-v1"])
tasks_v2 = APIRouter(prefix="/v2/tasks", tags=["tasks-v2"])


@tasks_v1.get("")
async def list_tasks_v1():
    # V1 implementation
    ...


@tasks_v2.get("")
async def list_tasks_v2():
    # V2 implementation with breaking changes
    ...
```

### Deprecation Headers

```yaml
paths:
  /v1/tasks:
    get:
      deprecated: true
      responses:
        '200':
          headers:
            Deprecation:
              schema:
                type: string
                example: "true"
            Sunset:
              schema:
                type: string
                example: "2025-01-01"
```

---

## Tooling

### Validation

```bash
# Validate OpenAPI spec
npx @apidevtools/swagger-cli validate openapi.yaml
```

### Linting

```bash
# Spectral - OpenAPI linter
npm install --save-dev @stoplight/spectral-cli

# Run linter
npx spectral lint openapi.yaml
```

### Diff

```bash
# Check breaking changes between versions
npx oasdiff diff openapi-v1.yaml openapi-v2.yaml
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
