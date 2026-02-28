import { Request, Response } from 'express'
import { ok } from '../../shared/utils/response'
import { adminService } from './admin.service'
import { updateUserSchema } from './admin.validation'

export const adminController = {
  async getStats(_req: Request, res: Response): Promise<void> {
    const stats = await adminService.getStats()
    ok(res, stats)
  },

  async getUsers(req: Request, res: Response): Promise<void> {
    const result = await adminService.getUsers(req.query as Record<string, string>)
    ok(res, result)
  },

  async updateUser(req: Request, res: Response): Promise<void> {
    const data = updateUserSchema.parse(req.body)
    const user = await adminService.updateUser(req.params.id, data)
    ok(res, user)
  },

  async getPendingNannies(req: Request, res: Response): Promise<void> {
    const result = await adminService.getPendingNannies(req.query as Record<string, string>)
    ok(res, result)
  },

  async getBookings(req: Request, res: Response): Promise<void> {
    const result = await adminService.getBookings(req.query as Record<string, string>)
    ok(res, result)
  },
}
