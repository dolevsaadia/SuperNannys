import { Request, Response, NextFunction } from 'express'
import { v4 as uuidv4 } from 'uuid'
import { logger } from '../utils/logger'

declare global {
  namespace Express {
    interface Request {
      requestId?: string
      startTime?: number
    }
  }
}

/**
 * Assigns a unique requestId to every incoming request and logs
 * the request start/end with timing. The requestId is also set
 * as a response header so clients can reference it in bug reports.
 */
export function requestContext(req: Request, res: Response, next: NextFunction): void {
  const requestId = (req.headers['x-request-id'] as string) || uuidv4()
  req.requestId = requestId
  req.startTime = Date.now()

  res.setHeader('X-Request-Id', requestId)

  const userId = req.user?.userId ?? 'anon'
  const role = req.user?.role ?? '-'

  logger.info('req:start', {
    requestId,
    method: req.method,
    path: req.path,
    userId,
    role,
    ip: req.ip,
    userAgent: req.headers['user-agent']?.substring(0, 80),
    contentLength: req.headers['content-length'],
  })

  // Log when response finishes
  res.on('finish', () => {
    const durationMs = Date.now() - (req.startTime ?? Date.now())
    const level = res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info'

    logger[level]('req:end', {
      requestId,
      method: req.method,
      path: req.path,
      status: res.statusCode,
      durationMs,
      userId: req.user?.userId ?? 'anon',
      role: req.user?.role ?? '-',
      contentLength: res.getHeader('content-length'),
    })

    // Warn on slow requests (> 3 seconds)
    if (durationMs > 3000) {
      logger.warn('req:slow', {
        requestId,
        method: req.method,
        path: req.path,
        durationMs,
        userId: req.user?.userId ?? 'anon',
      })
    }
  })

  next()
}
