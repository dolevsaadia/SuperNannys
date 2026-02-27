import { Request, Response, NextFunction } from 'express'
import { verifyToken, JwtPayload } from '../utils/jwt'
import { unauthorized, forbidden } from '../utils/response'

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
  try {
    req.user = verifyToken(header.slice(7))
    next()
  } catch {
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
