import { Request, Response, NextFunction } from 'express'

/**
 * Wraps an async route handler so that thrown errors
 * are forwarded to Express error middleware automatically.
 */
export const asyncHandler =
  (fn: (req: Request, res: Response, next: NextFunction) => Promise<void>) =>
  (req: Request, res: Response, next: NextFunction): void => {
    fn(req, res, next).catch(next)
  }
