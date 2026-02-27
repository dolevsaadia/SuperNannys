import { Response } from 'express'

export const ok = <T>(res: Response, data: T, status = 200) =>
  res.status(status).json({ success: true, data })

export const created = <T>(res: Response, data: T) => ok(res, data, 201)

export const fail = (res: Response, message: string, status = 400, errors?: unknown) =>
  res.status(status).json({ success: false, message, ...(errors ? { errors } : {}) })

export const unauthorized = (res: Response, message = 'Unauthorized') => fail(res, message, 401)
export const forbidden = (res: Response, message = 'Forbidden') => fail(res, message, 403)
export const notFound = (res: Response, message = 'Not found') => fail(res, message, 404)
