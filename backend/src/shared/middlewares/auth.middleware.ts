import { Request, Response, NextFunction } from 'express'
import { verifyToken, JwtPayload } from '../utils/jwt'
import { unauthorized, forbidden } from '../utils/response'
import { logger } from '../utils/logger'

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer ')) {
    unauthorized(res)
    return
  }

  const token = header.slice(7).trim()

  // Guard against empty, null-string, or malformed tokens that could
  // cause JWT verification to throw unexpectedly and crash the server.
  if (!token || token === 'null' || token === 'undefined' || token.length < 10) {
    logger.warn('Auth rejected: invalid token format', {
      requestId: req.requestId,
      path: req.path,
      tokenLength: token.length,
    })
    unauthorized(res, 'Invalid token format')
    return
  }

  try {
    req.user = verifyToken(token)
    next()
  } catch (err) {
    logger.debug('Auth token verification failed', {
      requestId: req.requestId,
      path: req.path,
      error: err instanceof Error ? err.message : String(err),
    })
    unauthorized(res, 'Invalid or expired token')
  }
}

export function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) { unauthorized(res); return }
    if (!roles.includes(req.user.role)) { forbidden(res); return }
    next()
  }
}
