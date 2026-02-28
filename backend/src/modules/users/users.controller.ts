import { Request, Response } from 'express'
import { ok } from '../../shared/utils/response'
import { parsePagination } from '../../shared/utils/pagination'
import { usersService } from './users.service'
import { updateProfileSchema, registerDeviceSchema } from './users.validation'

export const usersController = {
  async updateProfile(req: Request, res: Response): Promise<void> {
    const data = updateProfileSchema.parse(req.body)
    const user = await usersService.updateProfile(req.user!.userId, data)
    ok(res, user)
  },

  async getNotifications(req: Request, res: Response): Promise<void> {
    const pagination = parsePagination(req.query as Record<string, string>)
    const result = await usersService.getNotifications(req.user!.userId, pagination)
    ok(res, result)
  },

  async markAllNotificationsRead(req: Request, res: Response): Promise<void> {
    const result = await usersService.markAllNotificationsRead(req.user!.userId)
    ok(res, result)
  },

  async registerDevice(req: Request, res: Response): Promise<void> {
    const data = registerDeviceSchema.parse(req.body)
    const result = await usersService.registerDevice(req.user!.userId, data)
    ok(res, result)
  },

  async getEarnings(req: Request, res: Response): Promise<void> {
    const result = await usersService.getEarnings(req.user!.userId)
    ok(res, result)
  },
}
