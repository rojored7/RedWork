# API DX Design Patterns (Beautiful API)

Reference skill for Agent 10 (API-First Specification). Contains naming conventions, response standards, error patterns, pagination, filtering, rate limiting, and OpenAPI documentation patterns.

---

## 1. Naming Convention Cheat Sheet

### Resources

| Pattern | Correct | Wrong |
|---|---|---|
| Plural nouns | `/users`, `/tasks` | `/user`, `/task` |
| Sub-resources | `/projects/{id}/tasks` | `/tasks?projectId=x` |
| Non-CRUD actions | `POST /orders/{id}/cancel` | `PUT /orders/{id}` with `{"cancelled": true}` |
| Multi-word resources | `/user-profiles` (kebab-case) | `/userProfiles`, `/user_profiles` |
| Nested ownership | `/organizations/{orgId}/teams/{teamId}/members` | `/members?orgId=x&teamId=y` |

### Query Parameters

| Pattern | Correct | Wrong |
|---|---|---|
| Case style | `camelCase` consistently | mixed `snake_case` and `camelCase` |
| Pagination | `page`, `pageSize` | `p`, `ps`, `limit`, `offset` (pick one, use everywhere) |
| Sorting | `sortBy=createdAt`, `sortBy=-updatedAt` | `sort=createdAt:desc`, `order=desc&orderBy=x` |
| Filtering | `status=active` | `filter[status]=active`, `q=status:active` |
| Boolean | `isActive=true` | `inactive=false`, `active=1` |
| Date range | `createdAfter=2024-01-01`, `createdBefore=2024-12-31` | `dateFrom`, `date_start`, `startDate` |

### Operation IDs (for code generation)

| HTTP Method | Pattern | Example |
|---|---|---|
| GET (list) | `list{Resources}` | `listUsers`, `listProjectTasks` |
| GET (detail) | `get{Resource}ById` | `getUserById`, `getTaskById` |
| POST (create) | `create{Resource}` | `createUser`, `createTask` |
| PUT (full update) | `update{Resource}` | `updateUser`, `updateTask` |
| PATCH (partial) | `patch{Resource}` | `patchUser`, `patchTask` |
| DELETE | `delete{Resource}` | `deleteUser`, `deleteTask` |
| Action | `{verb}{Resource}` | `deactivateUser`, `cancelOrder` |

---

## 2. Response Envelope Standard

### Single Resource

```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "maria.garcia@example.com",
    "fullName": "Maria Garcia",
    "role": "admin",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T14:22:00Z"
  }
}
```

### Collection

```json
{
  "data": [
    { "id": "...", "title": "Task 1", "status": "active" },
    { "id": "...", "title": "Task 2", "status": "completed" }
  ],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalPages": 8,
    "totalItems": 150
  }
}
```

### Empty Collection (NEVER 404)

```json
{
  "data": [],
  "pagination": {
    "currentPage": 1,
    "pageSize": 20,
    "totalPages": 0,
    "totalItems": 0
  }
}
```

### Status Code Rules

| Operation | Success Code | Returns |
|---|---|---|
| GET (detail) | 200 | `{"data": {...}}` |
| GET (list) | 200 | `{"data": [...], "pagination": {...}}` |
| POST (create) | 201 | `{"data": {...}}` + `Location` header |
| PUT/PATCH | 200 | `{"data": {...}}` (always return updated resource) |
| DELETE | 204 | No body |
| Action (cancel, etc.) | 200 | `{"data": {...}}` (return updated resource) |

---

## 3. Error Response Standard

### Structure

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Task with ID abc-123 not found",
    "suggestion": "Verify the task ID or list all tasks: GET /api/v1/tasks",
    "timestamp": "2024-01-15T10:30:00Z",
    "path": "/api/v1/tasks/abc-123",
    "requestId": "req-789xyz"
  }
}
```

### Validation Error (Multiple Fields)

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Request validation failed with 2 errors",
    "details": [
      {
        "field": "email",
        "value": "not-an-email",
        "constraint": "isEmail",
        "message": "Must be a valid email address",
        "suggestion": "Use format: user@domain.com"
      },
      {
        "field": "password",
        "value": null,
        "constraint": "minLength",
        "message": "Must be at least 12 characters",
        "suggestion": "Use a mix of letters, numbers, and symbols"
      }
    ],
    "timestamp": "2024-01-15T10:30:00Z",
    "path": "/api/v1/users"
  }
}
```

### Standard Error Codes

| HTTP Status | Error Code | When | Suggestion Pattern |
|---|---|---|---|
| 400 | `VALIDATION_FAILED` | Invalid request body | Per-field guidance |
| 400 | `BAD_REQUEST` | Malformed request | "Check request format" |
| 401 | `UNAUTHORIZED` | No/invalid token | "Include Bearer token in Authorization header" |
| 401 | `TOKEN_EXPIRED` | Expired JWT | "Use POST /api/v1/auth/refresh to obtain a new token" |
| 403 | `FORBIDDEN` | Insufficient permissions | "Requires scope: {scope}" |
| 404 | `RESOURCE_NOT_FOUND` | Entity not found | "Verify the {resource} ID or list all: GET /api/v1/{resources}" |
| 409 | `CONFLICT` | Duplicate or state conflict | "A {resource} with this {field} already exists" |
| 422 | `BUSINESS_RULE_VIOLATION` | Domain rule broken | Explain the rule |
| 429 | `RATE_LIMITED` | Too many requests | "Retry after {seconds} seconds" |
| 500 | `INTERNAL_ERROR` | Server error | "Try again later. If persists, contact support" |

---

## 4. Pagination Standard

### Request

```
GET /api/v1/tasks?page=2&pageSize=20&sortBy=-createdAt&status=active
```

### Response

```json
{
  "data": [ ... ],
  "pagination": {
    "currentPage": 2,
    "pageSize": 20,
    "totalPages": 8,
    "totalItems": 150,
    "hasNextPage": true,
    "hasPreviousPage": true
  }
}
```

### Rules

- Default `pageSize`: 20
- Maximum `pageSize`: 100 (reject larger with 400)
- Page numbering starts at 1 (not 0)
- `totalItems` and `totalPages` always included
- `hasNextPage` / `hasPreviousPage` for easy client-side navigation

---

## 5. Filtering and Sorting Cheat Sheet

### Filtering

Simple key=value on query params. Multiple values for same field use comma:

```
GET /api/v1/tasks?status=active&priority=high
GET /api/v1/tasks?status=active,pending         # OR within same field
GET /api/v1/tasks?createdAfter=2024-01-01       # date range
GET /api/v1/tasks?search=deploy                  # full-text search
```

### Sorting

Prefix with `-` for descending. Multiple sort fields with comma:

```
GET /api/v1/tasks?sortBy=priority,-createdAt
```

This sorts by priority ascending, then by createdAt descending.

### OpenAPI Definition

```yaml
parameters:
  - name: page
    in: query
    schema: { type: integer, minimum: 1, default: 1 }
    description: Page number (starts at 1)
  - name: pageSize
    in: query
    schema: { type: integer, minimum: 1, maximum: 100, default: 20 }
    description: Number of items per page (max 100)
  - name: sortBy
    in: query
    schema: { type: string, default: "-createdAt" }
    description: "Sort field. Prefix with - for descending. Example: -createdAt, priority"
    example: "-createdAt"
  - name: status
    in: query
    schema: { type: string, enum: [active, completed, archived] }
    description: Filter by task status
```

---

## 6. Rate Limiting Headers

### On Every Response

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1705312800
```

### On 429 Too Many Requests

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 45
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705312800
Content-Type: application/json

{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded",
    "suggestion": "Retry after 45 seconds. Current limit: 100 requests/minute",
    "retryAfter": 45
  }
}
```

### Rate Limit Tiers (document in OpenAPI `info.description`)

| Tier | Limit | Scope |
|---|---|---|
| Anonymous | 20 req/min | IP-based |
| Authenticated | 100 req/min | User-based |
| Admin | 500 req/min | User-based |
| Auth endpoints | 5 req/min | IP-based (brute force protection) |

### OpenAPI Header Definition (reusable)

```yaml
components:
  headers:
    X-RateLimit-Limit:
      description: Maximum requests allowed per window
      schema: { type: integer }
      example: 100
    X-RateLimit-Remaining:
      description: Requests remaining in current window
      schema: { type: integer }
      example: 87
    X-RateLimit-Reset:
      description: Unix timestamp when the rate limit window resets
      schema: { type: integer }
      example: 1705312800
```

---

## 7. OpenAPI Property-Level Examples Template

Every schema property should have a `description` and `example`:

```yaml
components:
  schemas:
    UserDto:
      type: object
      required: [id, email, fullName, role, createdAt]
      properties:
        id:
          type: string
          format: uuid
          description: Unique identifier for the user
          example: "550e8400-e29b-41d4-a716-446655440000"
        email:
          type: string
          format: email
          description: User's primary email address, used for login and notifications
          example: "maria.garcia@example.com"
        fullName:
          type: string
          minLength: 2
          maxLength: 100
          description: User's display name
          example: "Maria Garcia"
        role:
          type: string
          enum: [user, admin, moderator]
          description: User's role determining access permissions
          example: "admin"
        avatarUrl:
          type: string
          format: uri
          nullable: true
          description: URL to user's profile picture. Null if not set.
          example: "https://cdn.example.com/avatars/550e8400.jpg"
        createdAt:
          type: string
          format: date-time
          description: Timestamp when the user account was created
          example: "2024-01-15T10:30:00Z"
        lastLoginAt:
          type: string
          format: date-time
          nullable: true
          description: Timestamp of user's most recent login. Null if never logged in.
          example: "2024-03-20T08:15:00Z"

    CreateUserDto:
      type: object
      required: [email, password, fullName]
      properties:
        email:
          type: string
          format: email
          maxLength: 255
          description: Email address for the new account. Must be unique.
          example: "new.user@example.com"
        password:
          type: string
          format: password
          minLength: 12
          maxLength: 128
          description: Account password. Minimum 12 characters with mixed case, numbers, and symbols.
          example: "S3cure!Pass#2024"
        fullName:
          type: string
          minLength: 2
          maxLength: 100
          description: Display name for the new user
          example: "Carlos Mendez"
```

---

## 8. Security Endpoint Patterns

### Auth Flow

```yaml
paths:
  /api/v1/auth/register:
    post:
      summary: Register a new user account
      description: Creates a new user with email verification pending.
      tags: [Authentication]
      security: []  # Public endpoint
      operationId: registerUser

  /api/v1/auth/login:
    post:
      summary: Authenticate and receive tokens
      description: >
        Returns access token (short-lived, 15min) and refresh token (long-lived, 7d).
        Access token goes in Authorization header for all subsequent requests.
      tags: [Authentication]
      security: []  # Public endpoint
      operationId: loginUser

  /api/v1/auth/refresh:
    post:
      summary: Refresh an expired access token
      description: >
        Exchange a valid refresh token for a new access token.
        Use this when receiving 401 with code TOKEN_EXPIRED.
      tags: [Authentication]
      security: []  # Uses refresh token in body, not bearer
      operationId: refreshToken

  /api/v1/auth/logout:
    post:
      summary: Invalidate current session tokens
      tags: [Authentication]
      security:
        - BearerAuth: []
      operationId: logoutUser
```

### Scopes Documentation

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: >
        JWT access token. Obtain via POST /api/v1/auth/login.
        Include in Authorization header: `Bearer <token>`.
        Token expires in 15 minutes. Refresh via POST /api/v1/auth/refresh.

# Per-endpoint scope documentation:
paths:
  /api/v1/users:
    get:
      security:
        - BearerAuth: []
      description: >
        List all users. Requires scope: read:users.
        Admin users see all users. Regular users see only their organization members.
```
