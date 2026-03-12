import { Request, Response } from 'express'
import type { RecurringBookingStatus } from '@prisma/client'
import { ok, created } from '../../shared/utils/response'
import { recurringBookingsService } from './recurring-bookings.service'
import {
  createRecurringBookingSchema,
  updateRecurringBookingSchema,
  updateStatusSchema,
} from './recurring-bookings.validation'

export const recurringBookingsController = {
  async create(req: Request, res: Response): Promise<void> {
    const data = createRecurringBookingSchema.parse(req.body)
    const result = await recurringBookingsService.create(req.user!.userId, data)
    created(res, result)
  },

  async list(req: Request, res: Response): Promise<void> {
    const { status, page, limit } = req.query as Record<string, string>
    const result = await recurringBookingsService.list(
      req.user!.userId,
      req.user!.role,
      { status, page, limit },
    )
    ok(res, result)
  },

  async getById(req: Request, res: Response): Promise<void> {
    const result = await recurringBookingsService.getById(
      req.user!.userId,
      req.user!.role,
      req.params.id,
    )
    ok(res, result)
  },

  async update(req: Request, res: Response): Promise<void> {
    const data = updateRecurringBookingSchema.parse(req.body)
    const result = await recurringBookingsService.update(
      req.user!.userId,
      req.user!.role,
      req.params.id,
      data,
    )
    ok(res, result)
  },

  async updateStatus(req: Request, res: Response): Promise<void> {
    const { status } = updateStatusSchema.parse(req.body)
    const result = await recurringBookingsService.updateStatus(
      req.user!.userId,
      req.user!.role,
      req.params.id,
      status as RecurringBookingStatus,
    )
    ok(res, result)
  },
}
