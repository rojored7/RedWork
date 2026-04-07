# Security Best Practices

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 19 (Security Review), Agent 10 (Backend)
**Purpose**: Comprehensive security patterns and OWASP Top 10 mitigations

---

## Input Validation

### Backend Validation (NestJS)

```typescript
import { IsEmail, IsString, MinLength, MaxLength, Matches } from 'class-validator';

export class CreateUserDto {
  @IsEmail()
  @MaxLength(255)
  email: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
  password: string;

  @IsString()
  @MinLength(2)
  @MaxLength(100)
  @Matches(/^[a-zA-Z\s'-]+$/)
  name: string;
}

// Usage in controller
@Post('register')
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))
async register(@Body() dto: CreateUserDto) {
  return this.authService.register(dto);
}
```

### Frontend Validation

```typescript
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Invalid email').max(255),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(128)
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
      'Password must include uppercase, lowercase, number, and special character'
    ),
});

// Usage in form
const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(loginSchema),
});
```

---

## Authentication & Authorization

### JWT Best Practices

```typescript
// Generate secure tokens
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  async generateTokens(userId: string) {
    const payload = { sub: userId };

    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET'),
      expiresIn: '15m', // Short-lived
    });

    const refreshToken = await this.jwtService.signAsync(payload, {
      secret: this.config.get('JWT_REFRESH_SECRET'),
      expiresIn: '7d',
    });

    return { accessToken, refreshToken };
  }

  async refreshAccessToken(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: this.config.get('JWT_REFRESH_SECRET'),
      });

      // Check if refresh token is blacklisted
      const isBlacklisted = await this.tokenBlacklistService.isBlacklisted(
        refreshToken
      );
      if (isBlacklisted) {
        throw new UnauthorizedException('Token has been revoked');
      }

      return this.generateTokens(payload.sub);
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}
```

### Secure Password Hashing

```typescript
import * as bcrypt from 'bcrypt';

export class PasswordService {
  private readonly SALT_ROUNDS = 12; // OWASP recommendation

  async hash(plainPassword: string): Promise<string> {
    return bcrypt.hash(plainPassword, this.SALT_ROUNDS);
  }

  async verify(plainPassword: string, hashedPassword: string): Promise<boolean> {
    return bcrypt.compare(plainPassword, hashedPassword);
  }
}

// NEVER store passwords in plain text
// NEVER use weak hashing (MD5, SHA1)
// ALWAYS use bcrypt, argon2, or scrypt
```

### Authorization Guards

```typescript
import { CanActivate, ExecutionContext } from '@nestjs/common';

@Injectable()
export class OwnershipGuard implements CanActivate {
  constructor(
    private projectRepository: ProjectRepository,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const userId = request.user.id;
    const projectId = request.params.id;

    const project = await this.projectRepository.findById(projectId);

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    // Verify ownership
    if (project.ownerId !== userId) {
      throw new ForbiddenException('You do not own this resource');
    }

    return true;
  }
}

// Usage
@UseGuards(JwtAuthGuard, OwnershipGuard)
@Delete(':id')
async deleteProject(@Param('id') id: string) {
  return this.projectService.delete(id);
}
```

---

## XSS Prevention

### Backend Response Sanitization

```typescript
import { Injectable } from '@nestjs/common';
import * as sanitizeHtml from 'sanitize-html';

@Injectable()
export class SanitizationService {
  sanitizeUserInput(input: string): string {
    return sanitizeHtml(input, {
      allowedTags: [], // No HTML allowed
      allowedAttributes: {},
    });
  }

  sanitizeRichText(input: string): string {
    return sanitizeHtml(input, {
      allowedTags: ['b', 'i', 'em', 'strong', 'a', 'p', 'ul', 'li'],
      allowedAttributes: {
        'a': ['href'],
      },
      allowedSchemes: ['http', 'https', 'mailto'],
    });
  }
}
```

### Frontend XSS Protection

```typescript
// BAD - Dangerous innerHTML
function UserComment({ comment }: { comment: string }) {
  return <div dangerouslySetInnerHTML={{ __html: comment }} />;
}

// GOOD - React auto-escapes
function UserComment({ comment }: { comment: string }) {
  return <div>{comment}</div>;
}

// GOOD - Sanitize if HTML is needed
import DOMPurify from 'dompurify';

function RichComment({ comment }: { comment: string }) {
  const sanitized = DOMPurify.sanitize(comment);
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}
```

---

## CSRF Prevention

### Backend CSRF Protection

```typescript
import { csurf } from 'csurf';

// Enable CSRF protection
app.use(csurf({ cookie: true }));

// Send CSRF token to client
@Get('csrf-token')
getCsrfToken(@Req() req: Request) {
  return { csrfToken: req.csrfToken() };
}

// Validate CSRF on state-changing operations
@Post('transfer')
@UseGuards(CsrfGuard)
async transfer(@Body() dto: TransferDto) {
  return this.transferService.execute(dto);
}
```

### Frontend CSRF Handling

```typescript
// Fetch CSRF token on app load
useEffect(() => {
  async function fetchCsrfToken() {
    const response = await fetch('/api/csrf-token');
    const { csrfToken } = await response.json();
    localStorage.setItem('csrfToken', csrfToken);
  }
  fetchCsrfToken();
}, []);

// Include CSRF token in requests
async function submitForm(data: FormData) {
  const csrfToken = localStorage.getItem('csrfToken');

  await fetch('/api/transfer', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
    },
    body: JSON.stringify(data),
  });
}
```

---

## SQL Injection Prevention

### Use ORMs with Parameterization

```typescript
// GOOD - TypeORM parameterized query
async findUserByEmail(email: string): Promise<User | null> {
  return this.userRepository.findOne({
    where: { email }, // Parameterized
  });
}

// GOOD - Query builder with parameters
async searchUsers(searchTerm: string): Promise<User[]> {
  return this.userRepository
    .createQueryBuilder('user')
    .where('user.name LIKE :searchTerm', { searchTerm: `%${searchTerm}%` })
    .getMany();
}

// BAD - String concatenation (SQL injection)
async searchUsers(searchTerm: string): Promise<User[]> {
  const query = `SELECT * FROM users WHERE name LIKE '%${searchTerm}%'`;
  return this.userRepository.query(query); // VULNERABLE
}
```

---

## Secrets Management

### Environment Variables

```typescript
// .env (NEVER commit to git)
JWT_ACCESS_SECRET=your-super-secret-key-min-32-chars
JWT_REFRESH_SECRET=another-super-secret-key-min-32-chars
DATABASE_URL=postgresql://user:pass@localhost:5432/db

// .gitignore
.env
.env.local
.env.*.local
```

### Centralized Configuration

```typescript
// config/configuration.ts
export default () => ({
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessExpiration: '15m',
    refreshExpiration: '7d',
  },
  database: {
    url: process.env.DATABASE_URL,
  },
});

// NEVER hardcode secrets
// BAD
const secret = 'my-secret-key'; // NEVER DO THIS

// GOOD
const secret = this.config.get('JWT_ACCESS_SECRET');
```

---

## Rate Limiting

### Backend Rate Limiting

```typescript
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // Time window in seconds
      limit: 10, // Max requests per window
    }),
  ],
})
export class AppModule {}

// Apply to specific endpoints
@UseGuards(ThrottlerGuard)
@Post('login')
async login(@Body() dto: LoginDto) {
  return this.authService.login(dto);
}

// Custom rate limit for sensitive endpoints
@Throttle(3, 60) // 3 requests per minute
@Post('forgot-password')
async forgotPassword(@Body() dto: ForgotPasswordDto) {
  return this.authService.forgotPassword(dto);
}
```

---

## CORS Configuration

```typescript
import { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';

const corsOptions: CorsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true, // Allow cookies
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-CSRF-Token'],
  exposedHeaders: ['X-Total-Count'],
  maxAge: 3600, // Cache preflight for 1 hour
};

app.enableCors(corsOptions);

// NEVER use origin: '*' in production
```

---

## Security Headers

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  noSniff: true,
  xssFilter: true,
  hidePoweredBy: true,
}));
```

---

## File Upload Security

```typescript
import { diskStorage } from 'multer';
import { extname } from 'path';

const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.pdf'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

@Post('upload')
@UseInterceptors(
  FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + extname(file.originalname));
      },
    }),
    fileFilter: (req, file, cb) => {
      const ext = extname(file.originalname).toLowerCase();
      if (!ALLOWED_EXTENSIONS.includes(ext)) {
        return cb(new BadRequestException('Invalid file type'), false);
      }
      cb(null, true);
    },
    limits: {
      fileSize: MAX_FILE_SIZE,
    },
  }),
)
async uploadFile(@UploadedFile() file: Express.Multer.File) {
  // Validate file content (not just extension)
  const fileType = await this.fileValidationService.detectFileType(file.path);

  if (!this.isAllowedFileType(fileType)) {
    fs.unlinkSync(file.path); // Delete invalid file
    throw new BadRequestException('File content does not match extension');
  }

  return { filename: file.filename };
}
```

---

## Logging Security Events

```typescript
@Injectable()
export class SecurityLogger {
  private readonly logger = new Logger('Security');

  logLoginAttempt(email: string, success: boolean, ip: string) {
    this.logger.log({
      event: 'LOGIN_ATTEMPT',
      email,
      success,
      ip,
      timestamp: new Date().toISOString(),
    });
  }

  logPasswordChange(userId: string, ip: string) {
    this.logger.log({
      event: 'PASSWORD_CHANGE',
      userId,
      ip,
      timestamp: new Date().toISOString(),
    });
  }

  logSuspiciousActivity(userId: string, activity: string, ip: string) {
    this.logger.warn({
      event: 'SUSPICIOUS_ACTIVITY',
      userId,
      activity,
      ip,
      timestamp: new Date().toISOString(),
    });
  }

  // NEVER log sensitive data
  // BAD: this.logger.log({ password: user.password })
  // GOOD: this.logger.log({ userId: user.id })
}
```

---

## Error Handling

```typescript
// NEVER expose internal errors to clients
@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();

    // Log full error internally
    console.error(exception);

    // Send safe error to client
    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        message: exception.message,
      });
    }

    // Generic error for unknown exceptions
    return response.status(500).json({
      message: 'An error occurred. Please try again later.',
    });
  }
}

// BAD - Exposes internal details
throw new Error(`Database connection failed: ${connectionString}`);

// GOOD - Generic error
throw new InternalServerErrorException('Unable to process request');
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
