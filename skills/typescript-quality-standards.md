# TypeScript Quality Standards

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 20 (Linting), Agent 11 (Frontend), Agent 10 (Backend)
**Purpose**: TypeScript strict mode, linting rules, and code organization standards

---

## TypeScript Strict Mode

### tsconfig.json Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "allowUnusedLabels": false,
    "allowUnreachableCode": false,
    "exactOptionalPropertyTypes": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

---

## Type Safety

### Explicit Return Types

```typescript
// BAD - Implicit return type
function getUserById(id: string) {
  return userRepository.findById(id);
}

// GOOD - Explicit return type
function getUserById(id: string): Promise<User | null> {
  return userRepository.findById(id);
}

// BAD - any type
function processData(data: any): any {
  return data.value;
}

// GOOD - Proper typing
interface DataInput {
  value: string;
}

function processData(data: DataInput): string {
  return data.value;
}
```

### Strict Null Checks

```typescript
// GOOD - Handle null/undefined
function formatName(name: string | null | undefined): string {
  if (!name) {
    return 'Unknown';
  }
  return name.trim().toUpperCase();
}

// GOOD - Non-null assertion only when certain
function getUser(id: string): User {
  const user = userMap.get(id);
  if (!user) {
    throw new Error(`User ${id} not found`);
  }
  return user; // TypeScript knows user is not null here
}

// BAD - Unsafe non-null assertion
function getUser(id: string): User {
  return userMap.get(id)!; // Dangerous if user doesn't exist
}
```

### Type Guards

```typescript
// Type guard function
function isUser(obj: unknown): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'email' in obj &&
    'name' in obj
  );
}

// Usage
function processEntity(entity: User | Project) {
  if (isUser(entity)) {
    console.log(entity.email); // TypeScript knows it's a User
  } else {
    console.log(entity.description); // TypeScript knows it's a Project
  }
}

// Discriminated unions
type Result<T> =
  | { success: true; value: T }
  | { success: false; error: string };

function handleResult<T>(result: Result<T>): T {
  if (result.success) {
    return result.value; // TypeScript knows value exists
  } else {
    throw new Error(result.error); // TypeScript knows error exists
  }
}
```

---

## ESLint Configuration

### .eslintrc.js

```javascript
module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.json',
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint', 'import'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'prettier',
  ],
  rules: {
    // TypeScript-specific
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/explicit-module-boundary-types': 'error',
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unused-vars': [
      'error',
      { argsIgnorePattern: '^_' },
    ],
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/no-misused-promises': 'error',
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/no-unnecessary-type-assertion': 'error',
    '@typescript-eslint/prefer-nullish-coalescing': 'error',
    '@typescript-eslint/prefer-optional-chain': 'error',
    '@typescript-eslint/strict-boolean-expressions': 'error',

    // General code quality
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'no-debugger': 'error',
    'no-alert': 'error',
    'prefer-const': 'error',
    'no-var': 'error',
    'eqeqeq': ['error', 'always'],

    // Import organization
    'import/order': [
      'error',
      {
        groups: [
          'builtin',
          'external',
          'internal',
          'parent',
          'sibling',
          'index',
        ],
        'newlines-between': 'always',
        alphabetize: { order: 'asc', caseInsensitive: true },
      },
    ],
  },
};
```

---

## Code Organization

### File Structure

```
src/
├── modules/
│   ├── user/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.entity.ts
│   │   │   └── value-objects/
│   │   │       └── email.vo.ts
│   │   ├── application/
│   │   │   ├── dto/
│   │   │   │   └── create-user.dto.ts
│   │   │   ├── services/
│   │   │   │   └── user.service.ts
│   │   │   └── use-cases/
│   │   │       └── register-user.use-case.ts
│   │   ├── infrastructure/
│   │   │   └── persistence/
│   │   │       ├── entities/
│   │   │       │   └── user.entity.ts
│   │   │       └── repositories/
│   │   │           └── typeorm-user.repository.ts
│   │   ├── api/
│   │   │   ├── controllers/
│   │   │   │   └── user.controller.ts
│   │   │   ├── dto/
│   │   │   │   └── create-user-api.dto.ts
│   │   │   └── guards/
│   │   │       └── user-ownership.guard.ts
│   │   └── user.module.ts
```

### Naming Conventions

```typescript
// Classes - PascalCase
class UserService {}
class EmailValueObject {}

// Interfaces - PascalCase with 'I' prefix (optional)
interface IUserRepository {}
interface UserRepository {} // Also acceptable

// Types - PascalCase
type UserId = string;
type Result<T> = { success: boolean; value?: T };

// Enums - PascalCase
enum TaskStatus {
  TODO = 'TODO',
  IN_PROGRESS = 'IN_PROGRESS',
  DONE = 'DONE',
}

// Constants - UPPER_SNAKE_CASE
const MAX_RETRY_ATTEMPTS = 3;
const API_BASE_URL = 'https://api.example.com';

// Functions/Methods - camelCase
function getUserById(id: string): Promise<User> {}
async function createProject(data: CreateProjectDto): Promise<Project> {}

// Variables - camelCase
const userCount = 10;
let isAuthenticated = false;

// Private class members - camelCase with underscore prefix
class User {
  private _id: string;
  private _email: Email;
}

// Boolean variables - use 'is', 'has', 'can' prefix
const isActive = true;
const hasPermission = false;
const canEdit = true;
```

---

## Import Organization

This skill applies to **frontend TypeScript code (React)**. Backend is Python/FastAPI only.

```typescript
// 1. Built-in / React core
import { useState, useEffect, useMemo } from 'react';

// 2. External libraries
import { useQuery, useMutation } from '@tanstack/react-query';
import { z } from 'zod';

// 3. Internal modules (absolute imports)
import { Button } from '@/components/ui/Button';
import { useAuthStore } from '@/stores/auth-store';
import type { User } from '@/api/generated/types';

// 4. Relative imports (same feature)
import { UserCard } from './UserCard';
import { formatUserName } from '../utils/format';
```

---

## Error Handling

### Custom Error Classes

```typescript
// Base error
export class DomainError extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Specific errors
export class ValidationError extends DomainError {}
export class NotFoundError extends DomainError {}
export class UnauthorizedError extends DomainError {}

// Usage
function validateEmail(email: string): void {
  if (!email.includes('@')) {
    throw new ValidationError('Invalid email format');
  }
}
```

### Result Pattern

```typescript
export class Result<T> {
  private constructor(
    public readonly isSuccess: boolean,
    public readonly error?: string,
    private readonly _value?: T,
  ) {}

  public static ok<U>(value: U): Result<U> {
    return new Result<U>(true, undefined, value);
  }

  public static fail<U>(error: string): Result<U> {
    return new Result<U>(false, error);
  }

  public getValue(): T {
    if (!this.isSuccess) {
      throw new Error('Cannot get value from failed result');
    }
    return this._value!;
  }

  public get isFailure(): boolean {
    return !this.isSuccess;
  }
}

// Usage
function createUser(data: CreateUserDto): Result<User> {
  const emailResult = Email.create(data.email);
  if (emailResult.isFailure) {
    return Result.fail(emailResult.error);
  }

  const user = new User({
    email: emailResult.getValue(),
    name: data.name,
  });

  return Result.ok(user);
}
```

---

## Comments and Documentation

```typescript
// GOOD - Self-documenting code
function calculateTotalPrice(items: CartItem[]): number {
  return items.reduce((total, item) => total + item.price * item.quantity, 0);
}

// BAD - Unnecessary comment
function calculateTotalPrice(items: CartItem[]): number {
  // Loop through items and add price * quantity to total
  return items.reduce((total, item) => total + item.price * item.quantity, 0);
}

// GOOD - Complex logic explanation
/**
 * Calculates tax using progressive brackets.
 *
 * Tax brackets:
 * - 0-10000: 10%
 * - 10001-50000: 20%
 * - 50001+: 30%
 */
function calculateTax(income: number): number {
  if (income <= 10000) {
    return income * 0.1;
  } else if (income <= 50000) {
    return 1000 + (income - 10000) * 0.2;
  } else {
    return 9000 + (income - 50000) * 0.3;
  }
}

// GOOD - JSDoc for public APIs
/**
 * Registers a new user in the system.
 *
 * @param dto - User registration data
 * @returns The created user
 * @throws {ValidationError} If email is invalid
 * @throws {ConflictError} If email already exists
 */
async function registerUser(dto: RegisterUserDto): Promise<User> {
  // implementation
}
```

---

## Testing Standards

### Test File Naming

```
user.service.ts       → user.service.spec.ts
user.entity.ts        → user.entity.spec.ts
email.vo.ts           → email.vo.spec.ts
```

### Test Organization

```typescript
describe('UserService', () => {
  let service: UserService;
  let mockRepository: jest.Mocked<IUserRepository>;

  beforeEach(() => {
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findByEmail: jest.fn(),
    };
    service = new UserService(mockRepository);
  });

  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const dto = { email: 'test@example.com', name: 'Test' };
      mockRepository.save.mockResolvedValue(expect.any(Object));

      // Act
      const result = await service.createUser(dto);

      // Assert
      expect(result.isSuccess).toBe(true);
      expect(mockRepository.save).toHaveBeenCalledTimes(1);
    });

    it('should fail with invalid email', async () => {
      // Arrange
      const dto = { email: 'invalid', name: 'Test' };

      // Act
      const result = await service.createUser(dto);

      // Assert
      expect(result.isFailure).toBe(true);
      expect(result.error).toContain('email');
      expect(mockRepository.save).not.toHaveBeenCalled();
    });
  });
});
```

---

## Code Smells to Avoid

### Long Functions

```typescript
// BAD - Function too long (>50 lines)
function processOrder(order: Order) {
  // 100 lines of code
}

// GOOD - Extract to smaller functions
function processOrder(order: Order) {
  validateOrder(order);
  calculateTotals(order);
  applyDiscounts(order);
  processPayment(order);
  sendConfirmation(order);
}
```

### Magic Numbers

```typescript
// BAD
if (user.age >= 18) {
  // code
}

// GOOD
const LEGAL_AGE = 18;
if (user.age >= LEGAL_AGE) {
  // code
}
```

### Nested Conditionals

```typescript
// BAD - Deep nesting
function processUser(user: User | null) {
  if (user) {
    if (user.isActive) {
      if (user.hasPermission('admin')) {
        if (user.emailVerified) {
          // do something
        }
      }
    }
  }
}

// GOOD - Early returns
function processUser(user: User | null) {
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission('admin')) return;
  if (!user.emailVerified) return;

  // do something
}
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
