# API Client Patterns

**Skill Version**: 1.0
**Created**: 2026-04-07
**Used By**: Agent 11 (Frontend Development)
**Purpose**: Centralized API client, error handling, interceptors, token injection

---

## Centralized Axios Client

### Base Client Configuration

```typescript
// services/api.ts
import axios, { AxiosInstance, AxiosError, InternalAxiosRequestConfig } from 'axios';
import { config } from '@/config/runtime';

const api: AxiosInstance = axios.create({
  baseURL: config.apiBaseUrl,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;

// NEVER create multiple axios instances with different baseURLs
// BAD:
// const userApi = axios.create({ baseURL: 'http://localhost:3001/users' });
// const projectApi = axios.create({ baseURL: 'http://localhost:3001/projects' });

// GOOD:
// Use single api instance with proper endpoints
// api.get('/users')
// api.get('/projects')
```

---

## Request Interceptors

### Authentication Token Injection

```typescript
// services/api.ts
import { getAuthToken, getRefreshToken, setAuthToken } from '@/utils/auth';

// Request interceptor - Add auth token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getAuthToken();

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// NEVER hardcode tokens
// BAD:
// config.headers.Authorization = 'Bearer hardcoded-token';
```

### CSRF Token Injection

```typescript
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const csrfToken = localStorage.getItem('csrfToken');

    // Only add CSRF for state-changing operations
    if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(config.method?.toUpperCase() || '')) {
      if (csrfToken) {
        config.headers['X-CSRF-Token'] = csrfToken;
      }
    }

    return config;
  },
  (error) => Promise.reject(error)
);
```

---

## Response Interceptors

### Token Refresh on 401

```typescript
// services/api.ts
let isRefreshing = false;
let failedQueue: Array<{
  resolve: (token: string) => void;
  reject: (error: any) => void;
}> = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token!);
    }
  });

  failedQueue = [];
};

api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

    // Handle 401 Unauthorized
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // Queue request while token is being refreshed
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        })
          .then(token => {
            originalRequest.headers.Authorization = `Bearer ${token}`;
            return api(originalRequest);
          })
          .catch(err => Promise.reject(err));
      }

      originalRequest._retry = true;
      isRefreshing = true;

      const refreshToken = getRefreshToken();

      if (!refreshToken) {
        // No refresh token, redirect to login
        window.location.href = '/login';
        return Promise.reject(error);
      }

      try {
        const response = await axios.post(`${config.apiBaseUrl}/auth/refresh`, {
          refreshToken,
        });

        const { accessToken } = response.data;
        setAuthToken(accessToken);

        // Update authorization header
        originalRequest.headers.Authorization = `Bearer ${accessToken}`;

        processQueue(null, accessToken);

        return api(originalRequest);
      } catch (refreshError) {
        processQueue(refreshError, null);

        // Refresh failed, redirect to login
        window.location.href = '/login';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);
```

### Global Error Handling

```typescript
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError<{ message: string }>) => {
    // Network error
    if (!error.response) {
      console.error('Network error:', error.message);
      return Promise.reject({
        message: 'Network error. Please check your connection.',
        originalError: error,
      });
    }

    // Server error
    const status = error.response.status;
    const message = error.response.data?.message || 'An error occurred';

    switch (status) {
      case 400:
        console.error('Bad Request:', message);
        break;
      case 403:
        console.error('Forbidden:', message);
        break;
      case 404:
        console.error('Not Found:', message);
        break;
      case 500:
        console.error('Server Error:', message);
        break;
      default:
        console.error('Error:', message);
    }

    return Promise.reject({
      status,
      message,
      originalError: error,
    });
  }
);
```

---

## Type-Safe API Functions

### Generic Request Wrapper

```typescript
// services/api.ts
interface ApiResponse<T> {
  data: T;
  message?: string;
}

interface ApiError {
  message: string;
  status: number;
}

export async function get<T>(url: string, params?: any): Promise<T> {
  const response = await api.get<ApiResponse<T>>(url, { params });
  return response.data.data;
}

export async function post<T>(url: string, data?: any): Promise<T> {
  const response = await api.post<ApiResponse<T>>(url, data);
  return response.data.data;
}

export async function put<T>(url: string, data?: any): Promise<T> {
  const response = await api.put<ApiResponse<T>>(url, data);
  return response.data.data;
}

export async function del<T>(url: string): Promise<T> {
  const response = await api.delete<ApiResponse<T>>(url);
  return response.data.data;
}
```

### Domain-Specific API Functions

```typescript
// api/projectApi.ts
import { get, post, put, del } from '@/services/api';

export interface Project {
  id: string;
  name: string;
  description: string;
  ownerId: string;
}

export interface CreateProjectDto {
  name: string;
  description: string;
}

export const projectApi = {
  getAll: () => get<Project[]>('/projects'),

  getById: (id: string) => get<Project>(`/projects/${id}`),

  create: (data: CreateProjectDto) => post<Project>('/projects', data),

  update: (id: string, data: Partial<CreateProjectDto>) =>
    put<Project>(`/projects/${id}`, data),

  delete: (id: string) => del<void>(`/projects/${id}`),
};

// Usage in component
const projects = await projectApi.getAll();
const project = await projectApi.create({ name: 'New Project', description: 'Test' });
```

---

## React Query Integration

### Query Functions

```typescript
// hooks/useProjects.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { projectApi, Project, CreateProjectDto } from '@/api/projectApi';

export function useProjects() {
  return useQuery({
    queryKey: ['projects'],
    queryFn: projectApi.getAll,
  });
}

export function useProject(id: string) {
  return useQuery({
    queryKey: ['projects', id],
    queryFn: () => projectApi.getById(id),
    enabled: !!id,
  });
}

export function useCreateProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: projectApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    },
  });
}

export function useUpdateProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<CreateProjectDto> }) =>
      projectApi.update(id, data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
      queryClient.invalidateQueries({ queryKey: ['projects', variables.id] });
    },
  });
}

export function useDeleteProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: projectApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    },
  });
}
```

---

## Error Boundaries for API Calls

### API Error Handling Hook

```typescript
// hooks/useApiError.ts
import { useState } from 'react';
import { AxiosError } from 'axios';

interface ApiError {
  message: string;
  status?: number;
}

export function useApiError() {
  const [error, setError] = useState<ApiError | null>(null);

  const handleError = (err: unknown) => {
    if (err instanceof AxiosError) {
      setError({
        message: err.response?.data?.message || 'An error occurred',
        status: err.response?.status,
      });
    } else if (err instanceof Error) {
      setError({ message: err.message });
    } else {
      setError({ message: 'An unknown error occurred' });
    }
  };

  const clearError = () => setError(null);

  return { error, handleError, clearError };
}

// Usage in component
function ProjectList() {
  const { data: projects, isLoading } = useProjects();
  const { error, handleError, clearError } = useApiError();

  const deleteProject = useDeleteProject();

  const handleDelete = async (id: string) => {
    try {
      await deleteProject.mutateAsync(id);
    } catch (err) {
      handleError(err);
    }
  };

  if (error) {
    return (
      <div>
        <p>Error: {error.message}</p>
        <button onClick={clearError}>Dismiss</button>
      </div>
    );
  }

  // render projects...
}
```

---

## Request Cancellation

### AbortController Pattern

```typescript
// hooks/useSearchProjects.ts
import { useEffect, useState } from 'react';
import api from '@/services/api';

export function useSearchProjects(searchTerm: string) {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const controller = new AbortController();

    async function search() {
      if (!searchTerm) {
        setProjects([]);
        return;
      }

      setLoading(true);
      try {
        const response = await api.get('/projects/search', {
          params: { q: searchTerm },
          signal: controller.signal,
        });
        setProjects(response.data.data);
      } catch (error) {
        if (error.name !== 'CanceledError') {
          console.error('Search failed:', error);
        }
      } finally {
        setLoading(false);
      }
    }

    search();

    // Cleanup - cancel request on unmount or search term change
    return () => {
      controller.abort();
    };
  }, [searchTerm]);

  return { projects, loading };
}
```

---

## Request Retries

### Retry Logic with Exponential Backoff

```typescript
import axios, { AxiosError } from 'axios';

async function retryRequest<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  delay = 1000
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      const isLastAttempt = attempt === maxRetries;
      const isRetryableError =
        error instanceof AxiosError &&
        error.response &&
        [408, 429, 500, 502, 503, 504].includes(error.response.status);

      if (!isRetryableError || isLastAttempt) {
        throw error;
      }

      const backoffDelay = delay * Math.pow(2, attempt);
      console.log(`Retrying request (attempt ${attempt + 1}/${maxRetries}) in ${backoffDelay}ms`);

      await new Promise(resolve => setTimeout(resolve, backoffDelay));
    }
  }

  throw new Error('Max retries exceeded');
}

// Usage
export const projectApi = {
  getAll: () => retryRequest(() => get<Project[]>('/projects')),

  create: (data: CreateProjectDto) =>
    retryRequest(() => post<Project>('/projects', data)),
};
```

---

## File Upload

### Multipart Form Data

```typescript
// api/uploadApi.ts
import api from '@/services/api';

export async function uploadFile(
  file: File,
  onUploadProgress?: (progress: number) => void
): Promise<{ url: string }> {
  const formData = new FormData();
  formData.append('file', file);

  const response = await api.post('/upload', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    onUploadProgress: (progressEvent) => {
      if (progressEvent.total) {
        const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
        onUploadProgress?.(progress);
      }
    },
  });

  return response.data.data;
}

// Usage in component
function FileUpload() {
  const [progress, setProgress] = useState(0);

  const handleUpload = async (file: File) => {
    try {
      const result = await uploadFile(file, setProgress);
      console.log('Uploaded:', result.url);
    } catch (error) {
      console.error('Upload failed:', error);
    }
  };

  return (
    <div>
      <input type="file" onChange={(e) => handleUpload(e.target.files[0])} />
      {progress > 0 && <progress value={progress} max={100} />}
    </div>
  );
}
```

---

## Polling

### Polling Pattern

```typescript
// hooks/usePolling.ts
import { useEffect, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';

export function usePollingQuery<T>(
  queryKey: string[],
  queryFn: () => Promise<T>,
  interval: number = 5000,
  enabled: boolean = true
) {
  return useQuery({
    queryKey,
    queryFn,
    enabled,
    refetchInterval: enabled ? interval : false,
    refetchIntervalInBackground: false,
  });
}

// Usage
function TaskStatus({ taskId }: { taskId: string }) {
  const { data: task } = usePollingQuery(
    ['task-status', taskId],
    () => taskApi.getStatus(taskId),
    2000, // Poll every 2 seconds
    taskId !== null
  );

  return <div>Status: {task?.status}</div>;
}
```

---

**Version**: 1.0
**Last Updated**: 2026-04-07
