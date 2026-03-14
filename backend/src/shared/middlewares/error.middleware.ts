import { Request, Response, NextFunction } from 'express'
import { ZodError } from 'zod'
import { Prisma } from '@prisma/client'
import { AppError } from '../errors/app-error'
import { logger } from '../utils/logger'

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction): void {
  const requestId = req.requestId ?? 'unknown'

  // Known application errors — log at appropriate level
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error('AppError (server)', { requestId, message: err.message, statusCode: err.statusCode, path: req.path, stack: err.stack })
    } else {
      logger.warn('AppError', { requestId, message: err.message, statusCode: err.statusCode, path: req.path })
    }
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
      ...(err.errors ? { errors: err.errors } : {}),
    })
    return
  }

  // Zod validation errors
  if (err instanceof ZodError) {
    logger.warn('Validation error', { requestId, path: req.path, errors: err.flatten() })
    res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: err.flatten(),
    })
    return
  }

  // Prisma known errors — map to appropriate HTTP status
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    logger.error('Prisma error', { requestId, code: err.code, message: err.message, path: req.path })
    if (err.code === 'P2002') {
      res.status(409).json({ success: false, message: 'A record with this data already exists' })
      return
    }
    if (err.code === 'P2025') {
      res.status(404).json({ success: false, message: 'Record not found' })
      return
    }
    res.status(500).json({ success: false, message: 'Database error' })
    return
  }

  if (err instanceof Prisma.PrismaClientValidationError) {
    logger.error('Prisma validation error', { requestId, message: err.message, path: req.path })
    res.status(400).json({ success: false, message: 'Invalid data format' })
    return
  }

  // Prisma initialization / runtime errors
  if (err instanceof Prisma.PrismaClientInitializationError) {
    logger.error('Prisma init error', { requestId, message: err.message, path: req.path })
    res.status(503).json({ success: false, message: 'Database temporarily unavailable' })
    return
  }

  if (err instanceof Prisma.PrismaClientRustPanicError) {
    logger.error('Prisma rust panic', { requestId, message: err.message, path: req.path })
    res.status(500).json({ success: false, message: 'Database engine error' })
    return
  }

  // Unknown / unexpected errors — always log full stack
  logger.error('Unhandled error', { requestId, message: err.message, stack: err.stack, path: req.path, method: req.method })
  res.status(500).json({ success: false, message: 'Internal server error' })
}

export function notFoundMiddleware(req: Request, res: Response): void {
  logger.warn('Route not found', { requestId: req.requestId, method: req.method, path: req.path })
  res.status(404).json({ success: false, message: `Route ${req.method} ${req.path} not found` })
}
