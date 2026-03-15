/**
 * Base application error — all business errors extend this.
 * The errorHandler middleware maps these to proper HTTP responses.
 */
export class AppError extends Error {
  public readonly statusCode: number
  public readonly code: string
  public readonly errors?: unknown

  constructor(message: string, statusCode = 400, errors?: unknown, code?: string) {
    super(message)
    this.name = 'AppError'
    this.statusCode = statusCode
    this.code = code || 'APP_ERROR'
    this.errors = errors
  }
}

// ── Specific Error Classes ─────────────────────────────────

/** 404 — resource not found */
export class NotFoundError extends AppError {
  constructor(resource = 'Resource', id?: string) {
    super(id ? `${resource} (${id}) not found` : `${resource} not found`, 404, undefined, 'NOT_FOUND')
    this.name = 'NotFoundError'
  }
}

/** 409 — conflict (duplicate, overlap, state violation) */
export class ConflictError extends AppError {
  constructor(message: string, errors?: unknown) {
    super(message, 409, errors, 'CONFLICT')
    this.name = 'ConflictError'
  }
}

/** 401 — authentication required or token invalid */
export class AuthenticationError extends AppError {
  constructor(message = 'Authentication required') {
    super(message, 401, undefined, 'AUTH_REQUIRED')
    this.name = 'AuthenticationError'
  }
}

/** 403 — authenticated but not allowed */
export class ForbiddenError extends AppError {
  constructor(message = 'You do not have permission to perform this action') {
    super(message, 403, undefined, 'FORBIDDEN')
    this.name = 'ForbiddenError'
  }
}

/** 422 — validation error (business logic, not schema) */
export class ValidationError extends AppError {
  constructor(message: string, errors?: unknown) {
    super(message, 422, errors, 'VALIDATION_ERROR')
    this.name = 'ValidationError'
  }
}

/** 503 — service temporarily unavailable */
export class ServiceUnavailableError extends AppError {
  constructor(message = 'Service temporarily unavailable') {
    super(message, 503, undefined, 'SERVICE_UNAVAILABLE')
    this.name = 'ServiceUnavailableError'
  }
}

/** 429 — too many requests */
export class RateLimitError extends AppError {
  constructor(message = 'Too many requests. Please try again later.') {
    super(message, 429, undefined, 'RATE_LIMITED')
    this.name = 'RateLimitError'
  }
}

/** 400 — bad request (malformed input) */
export class BadRequestError extends AppError {
  constructor(message: string, errors?: unknown) {
    super(message, 400, errors, 'BAD_REQUEST')
    this.name = 'BadRequestError'
  }
}
