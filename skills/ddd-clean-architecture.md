# DDD/Clean Architecture Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agents 02, 05, 10, 13, 15, 09b
**Purpose**: Centralized authority on Domain-Driven Design and Clean Architecture implementation patterns

---

## Overview

This skill document provides **complete, authoritative guidance** on implementing Domain-Driven Design (DDD) and Clean Architecture patterns in TypeScript/JavaScript backends (particularly NestJS/FastAPI equivalents).

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

**TypeScript Pattern**:
```typescript
export class User {
  private readonly _id: string;
  private _email: Email; // Value object
  private _name: string;
  private _isActive: boolean;

  // PRIVATE constructor - prevents direct instantiation
  private constructor(props: {
    id: string;
    email: Email;
    name: string;
    isActive: boolean;
  }) {
    this._id = props.id;
    this._email = props.email;
    this._name = props.name;
    this._isActive = props.isActive;
  }

  // Factory method for NEW entities
  public static create(props: {
    email: string;
    name: string;
  }): Result<User> {
    // Validation
    const emailOrError = Email.create(props.email);
    if (emailOrError.isFailure) {
      return Result.fail<User>(emailOrError.error);
    }

    if (!props.name || props.name.trim().length < 2) {
      return Result.fail<User>('Name must be at least 2 characters');
    }

    // Create entity
    const user = new User({
      id: uuidv4(),
      email: emailOrError.getValue(),
      name: props.name.trim(),
      isActive: true, // Default for new users
    });

    return Result.ok<User>(user);
  }

  // Factory method for EXISTING entities (from persistence)
  public static reconstitute(props: {
    id: string;
    email: string;
    name: string;
    isActive: boolean;
  }): Result<User> {
    const emailOrError = Email.create(props.email);
    if (emailOrError.isFailure) {
      return Result.fail<User>(emailOrError.error);
    }

    const user = new User({
      id: props.id,
      email: emailOrError.getValue(),
      name: props.name,
      isActive: props.isActive,
    });

    return Result.ok<User>(user);
  }

  // Getters (no setters - use domain methods)
  get id(): string {
    return this._id;
  }

  get email(): Email {
    return this._email;
  }

  get name(): string {
    return this._name;
  }

  get isActive(): boolean {
    return this._isActive;
  }

  // Domain methods (business logic)
  public changeEmail(newEmail: string): Result<void> {
    const emailOrError = Email.create(newEmail);
    if (emailOrError.isFailure) {
      return Result.fail<void>(emailOrError.error);
    }

    this._email = emailOrError.getValue();
    return Result.ok<void>();
  }

  public deactivate(): Result<void> {
    if (!this._isActive) {
      return Result.fail<void>('User already deactivated');
    }

    this._isActive = false;
    return Result.ok<void>();
  }

  public activate(): Result<void> {
    if (this._isActive) {
      return Result.fail<void>('User already active');
    }

    this._isActive = true;
    return Result.ok<void>();
  }
}
```

### 2. Value Objects

**Definition**: Objects without identity, defined entirely by their attributes. Two value objects with the same attributes are considered identical.

**Key Characteristics**:
- No unique identifier
- Immutable (once created, cannot be changed)
- Equality based on attributes
- Encapsulates validation logic
- Can be shared across entities

**TypeScript Pattern**:
```typescript
export class Email {
  private readonly _value: string;

  // PRIVATE constructor
  private constructor(value: string) {
    this._value = value;
  }

  // Factory method - ONLY way to create
  public static create(email: string): Result<Email> {
    if (!email) {
      return Result.fail<Email>('Email is required');
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return Result.fail<Email>('Invalid email format');
    }

    return Result.ok<Email>(new Email(email.toLowerCase().trim()));
  }

  // Getter
  get value(): string {
    return this._value;
  }

  // Equality comparison
  public equals(other: Email): boolean {
    if (!other) return false;
    return this._value === other._value;
  }

  // String representation
  public toString(): string {
    return this._value;
  }
}
```

### 3. Aggregates

**Definition**: Cluster of entities and value objects treated as a single unit for data changes.

**Key Characteristics**:
- Has one root entity (Aggregate Root)
- Enforces consistency boundaries
- External objects can only reference the root
- Transactions should not span multiple aggregates

**Example**:
```typescript
// Order is Aggregate Root
export class Order {
  private readonly _id: string;
  private readonly _customerId: string;
  private _items: OrderItem[]; // Part of aggregate
  private _status: OrderStatus; // Value object
  private _total: Money; // Value object

  private constructor(props: OrderProps) {
    this._id = props.id;
    this._customerId = props.customerId;
    this._items = props.items;
    this._status = props.status;
    this._total = props.total;
  }

  public static create(props: {
    customerId: string;
  }): Result<Order> {
    const order = new Order({
      id: uuidv4(),
      customerId: props.customerId,
      items: [],
      status: OrderStatus.create('DRAFT').getValue(),
      total: Money.create(0, 'USD').getValue(),
    });

    return Result.ok<Order>(order);
  }

  // Domain method - modifies aggregate
  public addItem(productId: string, quantity: number, price: Money): Result<void> {
    if (this._status.value !== 'DRAFT') {
      return Result.fail<void>('Cannot add items to non-draft order');
    }

    const itemOrError = OrderItem.create({ productId, quantity, price });
    if (itemOrError.isFailure) {
      return Result.fail<void>(itemOrError.error);
    }

    this._items.push(itemOrError.getValue());
    this._recalculateTotal();

    return Result.ok<void>();
  }

  // Private method - enforces invariants
  private _recalculateTotal(): void {
    const total = this._items.reduce(
      (sum, item) => sum + item.subtotal.amount,
      0
    );
    this._total = Money.create(total, 'USD').getValue();
  }

  // Domain method - state transition
  public submit(): Result<void> {
    if (this._status.value !== 'DRAFT') {
      return Result.fail<void>('Order already submitted');
    }

    if (this._items.length === 0) {
      return Result.fail<void>('Cannot submit empty order');
    }

    this._status = OrderStatus.create('SUBMITTED').getValue();
    return Result.ok<void>();
  }
}

// OrderItem is part of Order aggregate (not a separate aggregate)
class OrderItem {
  private readonly _productId: string;
  private readonly _quantity: number;
  private readonly _price: Money;
  private readonly _subtotal: Money;

  private constructor(props: OrderItemProps) {
    this._productId = props.productId;
    this._quantity = props.quantity;
    this._price = props.price;
    this._subtotal = Money.create(
      props.price.amount * props.quantity,
      props.price.currency
    ).getValue();
  }

  public static create(props: {
    productId: string;
    quantity: number;
    price: Money;
  }): Result<OrderItem> {
    if (props.quantity <= 0) {
      return Result.fail<OrderItem>('Quantity must be positive');
    }

    return Result.ok<OrderItem>(new OrderItem(props));
  }

  get subtotal(): Money {
    return this._subtotal;
  }
}
```

---

## Result<T> Pattern

**Purpose**: Handle errors without exceptions, making error paths explicit and type-safe.

**Implementation**:
```typescript
export class Result<T> {
  public readonly isSuccess: boolean;
  public readonly isFailure: boolean;
  private readonly _error?: string;
  private readonly _value?: T;

  private constructor(isSuccess: boolean, error?: string, value?: T) {
    if (isSuccess && error) {
      throw new Error('InvalidOperation: A result cannot be successful and contain an error');
    }
    if (!isSuccess && !error) {
      throw new Error('InvalidOperation: A failing result needs an error message');
    }

    this.isSuccess = isSuccess;
    this.isFailure = !isSuccess;
    this._error = error;
    this._value = value;

    Object.freeze(this);
  }

  public static ok<U>(value?: U): Result<U> {
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

  public get error(): string {
    if (!this.isFailure) {
      throw new Error('Cannot get error from successful result');
    }

    return this._error!;
  }
}
```

**Usage**:
```typescript
// Creating entities
const userOrError = User.create({ email: 'john@example.com', name: 'John' });

if (userOrError.isFailure) {
  // Handle error
  console.error(userOrError.error);
  return;
}

const user = userOrError.getValue();

// Domain operations
const emailChangeResult = user.changeEmail('jane@example.com');

if (emailChangeResult.isFailure) {
  // Handle error
  throw new BadRequestException(emailChangeResult.error);
}
```

---

## Clean Architecture Layers

### Layer Structure

```
┌─────────────────────────────────────┐
│          API/Presentation           │  Controllers, DTOs, Guards
│  (framework-specific: NestJS/etc)  │
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
   - Pure TypeScript classes
   - Contains: Entities, Value Objects, Domain Services, Aggregates

2. **Application Layer**:
   - Depends on Domain Layer
   - NO dependencies on Infrastructure or API layers
   - Orchestrates domain objects
   - Defines interfaces for repositories (ports)
   - Contains: Use Cases, Application Services, DTOs

3. **Infrastructure Layer**:
   - Depends on Domain and Application layers
   - Implements repository interfaces
   - Contains framework-specific code (TypeORM entities)
   - Contains: Repository implementations, Mappers, External adapters

4. **API/Presentation Layer** (Outermost):
   - Depends on Application layer
   - Framework-specific (NestJS controllers, guards)
   - Handles HTTP concerns
   - Contains: Controllers, Guards, API DTOs, Middleware

---

## Repository Pattern

**Purpose**: Abstract persistence logic from domain, allowing domain to remain infrastructure-agnostic.

### Domain Layer: Repository Interface (Port)

```typescript
// src/modules/user/domain/repositories/user.repository.interface.ts
import { User } from '../entities/user.entity';
import { Email } from '../value-objects/email.vo';

export interface IUserRepository {
  save(user: User): Promise<void>;
  findById(id: string): Promise<User | null>;
  findByEmail(email: Email): Promise<User | null>;
  findAll(): Promise<User[]>;
  delete(id: string): Promise<void>;
}
```

### Infrastructure Layer: Repository Implementation (Adapter)

```typescript
// src/modules/user/infrastructure/persistence/typeorm-user.repository.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IUserRepository } from '../../domain/repositories/user.repository.interface';
import { User } from '../../domain/entities/user.entity';
import { Email } from '../../domain/value-objects/email.vo';
import { UserEntity } from './entities/user.entity'; // TypeORM entity
import { UserMapper } from './mappers/user.mapper';

@Injectable()
export class TypeOrmUserRepository implements IUserRepository {
  constructor(
    @InjectRepository(UserEntity)
    private readonly ormRepository: Repository<UserEntity>,
  ) {}

  async save(user: User): Promise<void> {
    const ormEntity = UserMapper.toPersistence(user);
    await this.ormRepository.save(ormEntity);
  }

  async findById(id: string): Promise<User | null> {
    const ormEntity = await this.ormRepository.findOne({ where: { id } });
    if (!ormEntity) return null;

    const userOrError = UserMapper.toDomain(ormEntity);
    if (userOrError.isFailure) {
      throw new Error(userOrError.error);
    }

    return userOrError.getValue();
  }

  async findByEmail(email: Email): Promise<User | null> {
    const ormEntity = await this.ormRepository.findOne({
      where: { email: email.value }
    });
    if (!ormEntity) return null;

    const userOrError = UserMapper.toDomain(ormEntity);
    if (userOrError.isFailure) {
      throw new Error(userOrError.error);
    }

    return userOrError.getValue();
  }

  async findAll(): Promise<User[]> {
    const ormEntities = await this.ormRepository.find();

    const users: User[] = [];
    for (const ormEntity of ormEntities) {
      const userOrError = UserMapper.toDomain(ormEntity);
      if (userOrError.isSuccess) {
        users.push(userOrError.getValue());
      }
    }

    return users;
  }

  async delete(id: string): Promise<void> {
    await this.ormRepository.delete(id);
  }
}
```

---

## Mapper Pattern

**Purpose**: Convert between domain entities and ORM/persistence entities without polluting domain with ORM concerns.

```typescript
// src/modules/user/infrastructure/persistence/mappers/user.mapper.ts
import { User } from '../../../domain/entities/user.entity';
import { Email } from '../../../domain/value-objects/email.vo';
import { UserEntity } from '../entities/user.entity'; // TypeORM entity
import { Result } from '../../../../../common/core/result';

export class UserMapper {
  // Domain → Persistence (ORM entity)
  public static toPersistence(user: User): UserEntity {
    const ormEntity = new UserEntity();
    ormEntity.id = user.id;
    ormEntity.email = user.email.value;
    ormEntity.name = user.name;
    ormEntity.isActive = user.isActive;
    return ormEntity;
  }

  // Persistence → Domain
  public static toDomain(ormEntity: UserEntity): Result<User> {
    return User.reconstitute({
      id: ormEntity.id,
      email: ormEntity.email,
      name: ormEntity.name,
      isActive: ormEntity.isActive,
    });
  }

  // Domain → API DTO (for responses)
  public static toDTO(user: User): UserDTO {
    return {
      id: user.id,
      email: user.email.value,
      name: user.name,
      isActive: user.isActive,
    };
  }
}
```

---

## Anti-Patterns to AVOID

### 1. Public Constructors
```typescript
// WRONG - public constructor
export class User {
  public constructor(public email: string, public name: string) {}
}

// RIGHT - private constructor + factory
export class User {
  private constructor(props: UserProps) { /* ... */ }
  public static create(props): Result<User> { /* ... */ }
}
```

### 2. Casting to Create Entities
```typescript
// WRONG - casting bypasses validation
const user = { email: 'test@example.com', name: 'Test' } as User;

// RIGHT - use factory method
const userOrError = User.create({ email: 'test@example.com', name: 'Test' });
const user = userOrError.getValue();
```

### 3. Throwing Exceptions in Domain
```typescript
// WRONG - exceptions in domain
export class User {
  changeEmail(email: string): void {
    if (!email.includes('@')) {
      throw new Error('Invalid email'); // NO!
    }
    this._email = email;
  }
}

// RIGHT - return Result<T>
export class User {
  changeEmail(email: string): Result<void> {
    const emailOrError = Email.create(email);
    if (emailOrError.isFailure) {
      return Result.fail<void>(emailOrError.error);
    }
    this._email = emailOrError.getValue();
    return Result.ok<void>();
  }
}
```

### 4. Anemic Domain Model
```typescript
// WRONG - anemic (just data, no behavior)
export class User {
  public email: string;
  public name: string;
}

// Business logic in service instead of domain
export class UserService {
  changeEmail(user: User, email: string) {
    // validation logic here - should be in User entity
  }
}

// RIGHT - rich domain model
export class User {
  public changeEmail(email: string): Result<void> {
    // validation + logic here
  }
}
```

### 5. Violating Layer Dependencies
```typescript
// WRONG - domain depends on infrastructure
// src/modules/user/domain/entities/user.entity.ts
import { Entity, Column } from 'typeorm'; // NO TypeORM in domain!

@Entity()
export class User { }

// RIGHT - domain is pure, infrastructure depends on domain
// Domain entity (pure TypeScript)
export class User {
  private readonly _id: string;
  // ...
}

// Infrastructure ORM entity (separate)
@Entity('users')
export class UserEntity {
  @PrimaryColumn()
  id: string;
  // ...
}
```

---

## Testing DDD Patterns

### Testing Entities with Factory Methods

```typescript
// user.entity.spec.ts
describe('User', () => {
  describe('create', () => {
    it('should create a user with valid data', () => {
      const result = User.create({
        email: 'john@example.com',
        name: 'John Doe',
      });

      expect(result.isSuccess).toBe(true);
      const user = result.getValue();
      expect(user.email.value).toBe('john@example.com');
      expect(user.name).toBe('John Doe');
      expect(user.isActive).toBe(true);
    });

    it('should fail with invalid email', () => {
      const result = User.create({
        email: 'invalid-email',
        name: 'John Doe',
      });

      expect(result.isFailure).toBe(true);
      expect(result.error).toContain('email');
    });
  });

  describe('changeEmail', () => {
    it('should change email successfully', () => {
      const user = User.create({
        email: 'old@example.com',
        name: 'John',
      }).getValue();

      const result = user.changeEmail('new@example.com');

      expect(result.isSuccess).toBe(true);
      expect(user.email.value).toBe('new@example.com');
    });
  });
});
```

### Testing with Repository Mocks

```typescript
// register-user.use-case.spec.ts
describe('RegisterUserUseCase', () => {
  let useCase: RegisterUserUseCase;
  let mockUserRepository: jest.Mocked<IUserRepository>;

  beforeEach(() => {
    mockUserRepository = {
      save: jest.fn(),
      findByEmail: jest.fn(),
    } as any;

    useCase = new RegisterUserUseCase(mockUserRepository);
  });

  it('should register a new user', async () => {
    mockUserRepository.findByEmail.mockResolvedValue(null);
    mockUserRepository.save.mockResolvedValue(undefined);

    const result = await useCase.execute({
      email: 'john@example.com',
      name: 'John Doe',
    });

    expect(result.isSuccess).toBe(true);
    expect(mockUserRepository.save).toHaveBeenCalledTimes(1);
  });

  it('should fail if email already exists', async () => {
    const existingUser = User.create({
      email: 'john@example.com',
      name: 'Existing',
    }).getValue();

    mockUserRepository.findByEmail.mockResolvedValue(existingUser);

    const result = await useCase.execute({
      email: 'john@example.com',
      name: 'John Doe',
    });

    expect(result.isFailure).toBe(true);
    expect(result.error).toContain('already exists');
    expect(mockUserRepository.save).not.toHaveBeenCalled();
  });
});
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
