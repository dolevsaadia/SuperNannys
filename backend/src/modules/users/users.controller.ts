import { Request, Response } from 'express'
import { ok } from '../../shared/utils/response'
import { parsePagination } from '../../shared/utils/pagination'
import { usersService } from './users.service'
import { updateProfileSchema, registerDeviceSchema } from './users.validation'

export const usersController = {
  async deleteAccount(req: Request, res: Response): Promise<void> {
    const result = await usersService.deleteAccount(req.user!.userId)
    ok(res, result)
  },

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

  async uploadAvatar(req: Request, res: Response): Promise<void> {
    if (!req.file) {
      res.status(400).json({ error: 'No file uploaded' })
      return
    }
    // Build full URL so clients can use it directly without resolving
    const protocol = req.get('x-forwarded-proto') || req.protocol
    const host = req.get('host')
    const avatarUrl = `${protocol}://${host}/uploads/${req.file.filename}`
    const user = await usersService.updateProfile(req.user!.userId, { avatarUrl })
    ok(res, user)
  },

  async getEarnings(req: Request, res: Response): Promise<void> {
    const result = await usersService.getEarnings(req.user!.userId)
    ok(res, result)
  },
}
