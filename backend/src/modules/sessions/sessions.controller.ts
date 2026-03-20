import { Request, Response } from 'express'
import { ok } from '../../shared/utils/response'
import { sessionsService } from './sessions.service'
import { bookingIdParamSchema } from './sessions.validation'

export const sessionsController = {
  async confirmStart(req: Request, res: Response): Promise<void> {
    const { bookingId } = bookingIdParamSchema.parse(req.params)
    const result = await sessionsService.confirmStart(
      req.user!.userId, req.user!.role, bookingId,
    )
    ok(res, result)
  },

  async requestEnd(req: Request, res: Response): Promise<void> {
    const { bookingId } = bookingIdParamSchema.parse(req.params)
    const result = await sessionsService.requestEnd(
      req.user!.userId, req.user!.role, bookingId,
    )
    ok(res, result)
  },

  async confirmEnd(req: Request, res: Response): Promise<void> {
    const { bookingId } = bookingIdParamSchema.parse(req.params)
    const result = await sessionsService.confirmEnd(
      req.user!.userId, req.user!.role, bookingId,
    )
    ok(res, result)
  },

  async getState(req: Request, res: Response): Promise<void> {
    const { bookingId } = bookingIdParamSchema.parse(req.params)
    const result = await sessionsService.getState(
      req.user!.userId, req.user!.role, bookingId,
    )
    ok(res, result)
  },

  async getActive(req: Request, res: Response): Promise<void> {
    const result = await sessionsService.getActive(req.user!.userId)
    ok(res, result)
  },
}
