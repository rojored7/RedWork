# Configuration Management

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 10 (Backend), Agent 11 (Frontend), Agent 12 (Infrastructure)
**Purpose**: Centralized configuration patterns, environment management, no hardcoded values

---

## Backend Configuration (NestJS)

### Centralized Configuration Module

```typescript
// config/configuration.ts
export default () => ({
  app: {
    port: parseInt(process.env.PORT || '3000', 10),
    env: process.env.NODE_ENV || 'development',
  },
  database: {
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT || '5432', 10),
    username: process.env.DATABASE_USERNAME,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessExpiration: process.env.JWT_ACCESS_EXPIRATION || '15m',
    refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || '7d',
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD,
  },
  email: {
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT || '587', 10),
    user: process.env.EMAIL_USER,
    password: process.env.EMAIL_PASSWORD,
    from: process.env.EMAIL_FROM,
  },
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
    credentials: true,
  },
});

// app.module.ts
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      envFilePath: ['.env.local', '.env'],
      validationSchema: Joi.object({
        NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
        PORT: Joi.number().default(3000),
        DATABASE_HOST: Joi.string().required(),
        JWT_ACCESS_SECRET: Joi.string().min(32).required(),
        JWT_REFRESH_SECRET: Joi.string().min(32).required(),
      }),
    }),
  ],
})
export class AppModule {}
```

### Using Configuration in Services

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(private configService: ConfigService) {}

  generateToken(userId: string): string {
    const secret = this.configService.get<string>('jwt.accessSecret');
    const expiresIn = this.configService.get<string>('jwt.accessExpiration');

    return jwt.sign({ sub: userId }, secret, { expiresIn });
  }

  isProduction(): boolean {
    return this.configService.get<string>('app.env') === 'production';
  }
}

// NEVER do this
// const secret = 'hardcoded-secret'; // BAD
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

```typescript
// config/features.ts
export interface FeatureFlags {
  enableNewDashboard: boolean;
  enableEmailNotifications: boolean;
  enableFileUpload: boolean;
  maxUploadSize: number;
}

export const featureFlags: FeatureFlags = {
  enableNewDashboard: process.env.FEATURE_NEW_DASHBOARD === 'true',
  enableEmailNotifications: process.env.FEATURE_EMAIL_NOTIFICATIONS === 'true',
  enableFileUpload: process.env.FEATURE_FILE_UPLOAD === 'true',
  maxUploadSize: parseInt(process.env.MAX_UPLOAD_SIZE || '5242880', 10), // 5MB default
};

// Usage in service
@Injectable()
export class NotificationService {
  constructor(private configService: ConfigService) {}

  async sendEmail(to: string, subject: string, body: string): Promise<void> {
    const emailEnabled = this.configService.get<boolean>('features.enableEmailNotifications');

    if (!emailEnabled) {
      console.log('Email notifications disabled, skipping');
      return;
    }

    await this.emailService.send(to, subject, body);
  }
}
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

### TypeORM Configuration

```typescript
// config/database.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getDatabaseConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get<string>('database.host'),
  port: configService.get<number>('database.port'),
  username: configService.get<string>('database.username'),
  password: configService.get<string>('database.password'),
  database: configService.get<string>('database.database'),
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  synchronize: configService.get<string>('app.env') === 'development',
  logging: configService.get<string>('app.env') === 'development',
  ssl: configService.get<string>('app.env') === 'production' ? {
    rejectUnauthorized: false,
  } : false,
});

// app.module.ts
@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: getDatabaseConfig,
    }),
  ],
})
export class AppModule {}
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

```typescript
// AWS Secrets Manager example
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

export async function getSecret(secretName: string): Promise<string> {
  const client = new SecretsManagerClient({
    region: process.env.AWS_REGION,
  });

  const command = new GetSecretValueCommand({
    SecretId: secretName,
  });

  const response = await client.send(command);
  return response.SecretString || '';
}

// Usage
async function bootstrap() {
  if (process.env.NODE_ENV === 'production') {
    const jwtSecret = await getSecret('prod/jwt-access-secret');
    process.env.JWT_ACCESS_SECRET = jwtSecret;
  }

  const app = await NestFactory.create(AppModule);
  await app.listen(3000);
}
```

### Vault Integration

```typescript
import * as vault from 'node-vault';

const vaultClient = vault({
  endpoint: process.env.VAULT_ADDR,
  token: process.env.VAULT_TOKEN,
});

export async function loadSecretsFromVault(): Promise<void> {
  const secrets = await vaultClient.read('secret/data/taskmanager');

  process.env.DATABASE_PASSWORD = secrets.data.data.database_password;
  process.env.JWT_ACCESS_SECRET = secrets.data.data.jwt_access_secret;
  process.env.JWT_REFRESH_SECRET = secrets.data.data.jwt_refresh_secret;
}
```

---

## Configuration Validation

### Joi Schema Validation

```typescript
import * as Joi from 'joi';

const configSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'staging', 'production', 'test')
    .default('development'),
  PORT: Joi.number().default(3000),

  DATABASE_HOST: Joi.string().required(),
  DATABASE_PORT: Joi.number().default(5432),
  DATABASE_USERNAME: Joi.string().required(),
  DATABASE_PASSWORD: Joi.string().required(),
  DATABASE_NAME: Joi.string().required(),

  JWT_ACCESS_SECRET: Joi.string().min(32).required(),
  JWT_REFRESH_SECRET: Joi.string().min(32).required(),
  JWT_ACCESS_EXPIRATION: Joi.string().default('15m'),
  JWT_REFRESH_EXPIRATION: Joi.string().default('7d'),

  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().default(6379),
  REDIS_PASSWORD: Joi.string().when('NODE_ENV', {
    is: 'production',
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),

  CORS_ORIGIN: Joi.string().default('http://localhost:3000'),
});

// Validate on startup
const { error, value: validatedEnv } = configSchema.validate(process.env, {
  abortEarly: false,
  allowUnknown: true,
});

if (error) {
  throw new Error(`Config validation error: ${error.message}`);
}
```

---

## Runtime Configuration Updates

### Hot Reload Configuration

```typescript
import { watch } from 'fs';
import { join } from 'path';

interface AppConfig {
  maxConnections: number;
  timeout: number;
  features: FeatureFlags;
}

class ConfigManager {
  private config: AppConfig;
  private configPath = join(__dirname, 'config.json');

  constructor() {
    this.loadConfig();
    this.watchConfig();
  }

  private loadConfig(): void {
    const data = readFileSync(this.configPath, 'utf-8');
    this.config = JSON.parse(data);
    console.log('Configuration loaded');
  }

  private watchConfig(): void {
    watch(this.configPath, (eventType) => {
      if (eventType === 'change') {
        this.loadConfig();
        console.log('Configuration reloaded');
      }
    });
  }

  get<K extends keyof AppConfig>(key: K): AppConfig[K] {
    return this.config[key];
  }
}

export const configManager = new ConfigManager();
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
