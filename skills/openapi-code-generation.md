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

## Backend NestJS Code Generation

### Manual DTO Creation from OpenAPI

```typescript
// src/modules/task/api/dto/create-task-api.dto.ts
import { IsString, IsEnum, IsOptional, IsUUID, MinLength, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum TaskStatus {
  TODO = 'TODO',
  IN_PROGRESS = 'IN_PROGRESS',
  DONE = 'DONE',
}

export enum TaskPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
}

export class CreateTaskApiDto {
  @ApiProperty({ minLength: 1, maxLength: 200 })
  @IsString()
  @MinLength(1)
  @MaxLength(200)
  title: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsString()
  @IsOptional()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ enum: TaskStatus, default: TaskStatus.TODO })
  @IsEnum(TaskStatus)
  @IsOptional()
  status?: TaskStatus;

  @ApiPropertyOptional({ enum: TaskPriority, default: TaskPriority.MEDIUM })
  @IsEnum(TaskPriority)
  @IsOptional()
  priority?: TaskPriority;

  @ApiPropertyOptional({ type: String, format: 'date-time' })
  @IsString()
  @IsOptional()
  dueDate?: string;

  @ApiProperty({ type: String, format: 'uuid' })
  @IsUUID()
  projectId: string;

  @ApiPropertyOptional({ type: String, format: 'uuid' })
  @IsUUID()
  @IsOptional()
  assigneeId?: string;
}
```

### Swagger UI Integration

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Swagger configuration
  const config = new DocumentBuilder()
    .setTitle('Task Manager API')
    .setDescription('RESTful API for task management system')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(3001);
}
bootstrap();
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

```typescript
// test/contract/api-contract.spec.ts
import * as request from 'supertest';
import { Test } from '@nestjs/testing';
import { AppModule } from '@/app.module';
import { INestApplication } from '@nestjs/common';
import * as OpenAPIValidator from 'express-openapi-validator';
import * as YAML from 'yamljs';

describe('API Contract Tests', () => {
  let app: INestApplication;
  const spec = YAML.load('./openapi.yaml');

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();

    // Add OpenAPI validator middleware
    app.use(
      OpenAPIValidator.middleware({
        apiSpec: spec,
        validateRequests: true,
        validateResponses: true,
      })
    );

    await app.init();
  });

  it('POST /tasks should match OpenAPI spec', async () => {
    const response = await request(app.getHttpServer())
      .post('/api/v1/tasks')
      .send({
        title: 'Test Task',
        projectId: '550e8400-e29b-41d4-a716-446655440000',
      });

    expect(response.status).toBe(201);
    // Validator automatically checks response matches spec
  });

  it('GET /tasks should match OpenAPI spec', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/tasks')
      .query({ status: 'TODO', limit: 20 });

    expect(response.status).toBe(200);
    // Validator automatically checks response structure
  });
});
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

```typescript
// NestJS controller
@Controller('v1/tasks')
export class TasksV1Controller {
  // V1 implementation
}

@Controller('v2/tasks')
export class TasksV2Controller {
  // V2 implementation with breaking changes
}
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
