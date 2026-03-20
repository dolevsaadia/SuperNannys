import { Request, Response, NextFunction } from 'express'
import { ZodError } from 'zod'
import { Prisma } from '@prisma/client'
import { AppError } from '../errors/app-error'
import { logger } from '../utils/logger'

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction): void {
  const requestId = req.requestId ?? 'unknown'

  // ── AppError (and all subclasses) ──────────────────────
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error('AppError (server)', { requestId, code: err.code, message: err.message, statusCode: err.statusCode, path: req.path, stack: err.stack })
    } else {
      logger.warn('AppError', { requestId, code: err.code, message: err.message, statusCode: err.statusCode, path: req.path })
    }
    res.status(err.statusCode).json({
      success: false,
      code: err.code,
      message: err.message,
      ...(err.errors ? { errors: err.errors } : {}),
    })
    return
  }

  // ── Zod validation errors ──────────────────────────────
  if (err instanceof ZodError) {
    logger.warn('Validation error', { requestId, path: req.path, errors: err.flatten() })
    res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: 'Validation failed',
      errors: err.flatten(),
    })
    return
  }

  // ── Prisma known request errors ────────────────────────
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    logger.error('Prisma error', { requestId, code: err.code, message: err.message, path: req.path })
    if (err.code === 'P2002') {
      res.status(409).json({ success: false, code: 'CONFLICT', message: 'A record with this data already exists' })
      return
    }
    if (err.code === 'P2025') {
      res.status(404).json({ success: false, code: 'NOT_FOUND', message: 'Record not found' })
      return
    }
    if (err.code === 'P2003') {
      res.status(400).json({ success: false, code: 'BAD_REQUEST', message: 'Referenced record does not exist' })
      return
    }
    res.status(500).json({ success: false, code: 'DATABASE_ERROR', message: 'Database error' })
    return
  }

  if (err instanceof Prisma.PrismaClientValidationError) {
    logger.error('Prisma validation error', { requestId, message: err.message, path: req.path })
    res.status(400).json({ success: false, code: 'BAD_REQUEST', message: 'Invalid data format' })
    return
  }

  // ── Prisma infra errors ────────────────────────────────
  if (err instanceof Prisma.PrismaClientInitializationError) {
    logger.error('Prisma init error', { requestId, message: err.message, path: req.path })
    res.status(503).json({ success: false, code: 'SERVICE_UNAVAILABLE', message: 'Database temporarily unavailable' })
    return
  }

  if (err instanceof Prisma.PrismaClientRustPanicError) {
    logger.error('Prisma rust panic', { requestId, message: err.message, path: req.path })
    res.status(500).json({ success: false, code: 'DATABASE_ERROR', message: 'Database engine error' })
    return
  }

  // ── JSON parse errors ──────────────────────────────────
  if (err instanceof SyntaxError && 'body' in err) {
    logger.warn('JSON parse error', { requestId, path: req.path, message: err.message })
    res.status(400).json({ success: false, code: 'BAD_REQUEST', message: 'Invalid JSON in request body' })
    return
  }

  // ── Payload too large ──────────────────────────────────
  if ('type' in err && (err as any).type === 'entity.too.large') {
    logger.warn('Payload too large', { requestId, path: req.path })
    res.status(413).json({ success: false, code: 'PAYLOAD_TOO_LARGE', message: 'Request body too large' })
    return
  }

  // ── Unknown / unexpected errors ────────────────────────
  logger.error('Unhandled error', {
    requestId,
    name: err.name,
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  })
  res.status(500).json({ success: false, code: 'INTERNAL_ERROR', message: 'Internal server error' })
}

export function notFoundMiddleware(req: Request, res: Response): void {
  logger.warn('Route not found', { requestId: req.requestId, method: req.method, path: req.path })
  res.status(404).json({ success: false, code: 'ROUTE_NOT_FOUND', message: `Route ${req.method} ${req.path} not found` })
}
