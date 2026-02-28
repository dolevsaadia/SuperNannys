import { Request, Response } from 'express'
import type { BookingStatus } from '@prisma/client'
import { ok, created } from '../../shared/utils/response'
import { bookingsService } from './bookings.service'
import { createBookingSchema, updateBookingStatusSchema } from './bookings.validation'

export const bookingsController = {
  async create(req: Request, res: Response): Promise<void> {
    const data = createBookingSchema.parse(req.body)
    const booking = await bookingsService.create(req.user!.userId, data)
    created(res, booking)
  },

  async list(req: Request, res: Response): Promise<void> {
    const { status, page, limit } = req.query as Record<string, string>
    const result = await bookingsService.list(req.user!.userId, req.user!.role, { status, page, limit })
    ok(res, result)
  },

  async getById(req: Request, res: Response): Promise<void> {
    const booking = await bookingsService.getById(req.user!.userId, req.user!.role, req.params.id)
    ok(res, booking)
  },

  async updateStatus(req: Request, res: Response): Promise<void> {
    const { status } = updateBookingStatusSchema.parse(req.body)
    const updated = await bookingsService.updateStatus(req.user!.userId, req.user!.role, req.params.id, status as BookingStatus)
    ok(res, updated)
  },
}
