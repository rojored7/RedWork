/**
 * Architecture Rules - Compliance Architecture System (CAS)
 *
 * These rules define the architectural constraints for the project.
 * They are enforced in ADVISORY mode by skill 06-validate-architecture.
 *
 * Purpose: Maintain clean architecture and prevent common anti-patterns.
 *
 * Usage:
 * - Customize rules below for your project
 * - Run validation: workflow-orchestrator skill 06-validate-architecture
 */

export const architectureRules = {
  /**
   * Layering Rules
   *
   * Defines which layers can import from which other layers.
   * This prevents violations like Controllers importing directly from Repositories.
   */
  layering: {
    controllers: {
      canImport: [
        'services',
        'types',
        'middleware',
        'utils/validation',
        'utils/logger'
      ],
      cannotImport: [
        'repositories',
        'utils/prisma',
        'utils/database'
      ],
      description: 'Controllers handle HTTP requests and delegate to Services'
    },

    services: {
      canImport: [
        'repositories',
        'types',
        'utils'
      ],
      cannotImport: [
        'controllers',
        'routes',
        'middleware'
      ],
      description: 'Services contain business logic and use Repositories for data'
    },

    repositories: {
      canImport: [
        'types',
        'utils/prisma',
        'utils/database'
      ],
      cannotImport: [
        'controllers',
        'services',
        'routes',
        'middleware'
      ],
      description: 'Repositories handle data access only'
    },

    middleware: {
      canImport: [
        'types',
        'utils',
        'services' // Only for auth verification
      ],
      cannotImport: [
        'controllers',
        'repositories'
      ],
      description: 'Middleware intercepts requests before controllers'
    },

    routes: {
      canImport: [
        'controllers',
        'middleware',
        'types'
      ],
      cannotImport: [
        'services',
        'repositories'
      ],
      description: 'Routes define endpoints and apply middleware'
    }
  },

  /**
   * Naming Conventions
   */
  naming: {
    files: {
      pattern: 'kebab-case',
      examples: ['user-service.ts', 'auth-controller.ts', 'error-handler.ts'],
      violations: ['UserService.ts', 'auth_controller.ts', 'errorHandler.ts']
    },

    classes: {
      pattern: 'PascalCase',
      examples: ['UserService', 'AuthController', 'ErrorHandler'],
      violations: ['userService', 'auth_controller', 'error_handler']
    },

    functions: {
      pattern: 'camelCase',
      examples: ['getUserById', 'validateToken', 'handleError'],
      violations: ['GetUserById', 'validate_token', 'handle-error']
    },

    constants: {
      pattern: 'UPPER_SNAKE_CASE',
      examples: ['MAX_RETRIES', 'DEFAULT_TIMEOUT', 'API_VERSION'],
      violations: ['maxRetries', 'defaultTimeout', 'apiVersion']
    },

    interfaces: {
      pattern: 'PascalCase',
      prefix: 'I',
      examples: ['IUser', 'IAuthService', 'IErrorHandler'],
      violations: ['User', 'authService', 'error_handler']
    },

    types: {
      pattern: 'PascalCase',
      examples: ['UserRole', 'AuthResponse', 'ErrorCode'],
      violations: ['userRole', 'auth_response', 'error-code']
    }
  },

  /**
   * File Organization
   */
  fileOrganization: {
    structure: {
      'controllers/': 'HTTP request handlers',
      'services/': 'Business logic',
      'repositories/': 'Data access layer',
      'middleware/': 'Express middleware',
      'routes/': 'Route definitions',
      'types/': 'TypeScript types and interfaces',
      'utils/': 'Helper functions and utilities',
      'config/': 'Configuration files',
      'validators/': 'Input validation schemas'
    },

    violations: [
      {
        pattern: 'src/*Helper.ts',
        message: 'Helper files should be in utils/ directory'
      },
      {
        pattern: 'src/*Util.ts',
        message: 'Util files should be in utils/ directory'
      },
      {
        pattern: 'src/controllers/*Service.ts',
        message: 'Service files should be in services/ directory'
      }
    ]
  },

  /**
   * Import Order
   */
  importOrder: {
    order: [
      'node:*',        // Node built-ins (node:fs, node:path)
      '*',             // External packages (express, prisma)
      '@/*',           // Internal aliases (@/services)
      './*', '../*'    // Relative imports
    ],
    description: 'Imports should be ordered: builtins → external → internal → relative'
  },

  /**
   * Code Quality Metrics
   */
  metrics: {
    maxFileSize: {
      value: 300,
      unit: 'lines',
      description: 'Files over 300 lines should be split'
    },

    maxFunctionComplexity: {
      value: 10,
      description: 'Cyclomatic complexity threshold'
    },

    maxFunctionLength: {
      value: 50,
      unit: 'lines',
      description: 'Functions over 50 lines should be refactored'
    },

    maxParameterCount: {
      value: 4,
      description: 'Functions with >4 parameters should use objects'
    }
  },

  /**
   * Anti-Patterns to Detect
   */
  antiPatterns: {
    noCircularDependencies: {
      enabled: true,
      severity: 'error',
      description: 'Circular dependencies cause initialization issues'
    },

    noDefaultExports: {
      enabled: true,
      exceptions: ['pages/', 'App.tsx', 'main.tsx'],
      severity: 'warning',
      description: 'Named exports are easier to refactor and track'
    },

    noAnyType: {
      enabled: true,
      severity: 'warning',
      description: 'Avoid using "any" type, use proper types or "unknown"'
    },

    noConsoleLogs: {
      enabled: true,
      exceptions: ['utils/logger.ts'],
      severity: 'info',
      description: 'Use proper logger instead of console.log'
    },

    noDuplicateCode: {
      enabled: true,
      threshold: 10, // lines
      severity: 'warning',
      description: 'Extract duplicate code into shared functions'
    }
  },

  /**
   * Testing Requirements
   */
  testing: {
    minCoverage: {
      lines: 70,
      functions: 70,
      branches: 60,
      statements: 70
    },

    testFileLocation: {
      pattern: '__tests__/',
      description: 'Test files should be in __tests__/ directory or next to source with .test.ts extension'
    },

    testNaming: {
      pattern: '*.test.ts or *.spec.ts',
      examples: ['user.test.ts', 'auth.spec.ts']
    }
  },

  /**
   * Documentation Requirements
   */
  documentation: {
    requireJSDoc: {
      enabled: true,
      for: ['public functions', 'classes', 'interfaces'],
      severity: 'info'
    },

    requireReadme: {
      enabled: true,
      for: ['services/', 'modules/'],
      severity: 'info'
    }
  }
};

/**
 * Validation Functions
 *
 * These are used by the validation skill to check rules.
 */
export const validators = {
  /**
   * Check if a file follows naming convention
   */
  validateFileName(fileName: string, expectedPattern: string): boolean {
    const patterns = {
      'kebab-case': /^[a-z0-9]+(-[a-z0-9]+)*\.(ts|tsx|js|jsx)$/,
      'PascalCase': /^[A-Z][a-zA-Z0-9]*\.(ts|tsx|js|jsx)$/,
      'camelCase': /^[a-z][a-zA-Z0-9]*\.(ts|tsx|js|jsx)$/
    };

    return patterns[expectedPattern]?.test(fileName) ?? false;
  },

  /**
   * Check if imports respect layering rules
   */
  validateLayering(
    currentLayer: string,
    importPath: string,
    rules: typeof architectureRules.layering
  ): { valid: boolean; reason?: string } {
    const layerRules = rules[currentLayer];
    if (!layerRules) {
      return { valid: true };
    }

    // Check if import is forbidden
    for (const forbidden of layerRules.cannotImport) {
      if (importPath.includes(forbidden)) {
        return {
          valid: false,
          reason: `${currentLayer} cannot import from ${forbidden}`
        };
      }
    }

    return { valid: true };
  },

  /**
   * Detect circular dependencies
   */
  detectCircularDependencies(dependencyGraph: Map<string, string[]>): string[][] {
    const cycles: string[][] = [];
    const visited = new Set<string>();
    const recursionStack = new Set<string>();

    function dfs(node: string, path: string[]) {
      visited.add(node);
      recursionStack.add(node);
      path.push(node);

      const neighbors = dependencyGraph.get(node) || [];
      for (const neighbor of neighbors) {
        if (!visited.has(neighbor)) {
          dfs(neighbor, [...path]);
        } else if (recursionStack.has(neighbor)) {
          // Cycle detected
          const cycleStart = path.indexOf(neighbor);
          cycles.push(path.slice(cycleStart));
        }
      }

      recursionStack.delete(node);
    }

    for (const node of dependencyGraph.keys()) {
      if (!visited.has(node)) {
        dfs(node, []);
      }
    }

    return cycles;
  }
};

export default architectureRules;
