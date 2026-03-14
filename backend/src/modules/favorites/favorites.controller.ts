import { Request, Response } from 'express'
import { z } from 'zod'
import { favoritesService } from './favorites.service'
import { ok } from '../../shared/utils/response'

export const favoritesController = {
  async toggle(req: Request, res: Response): Promise<void> {
    const { nannyUserId } = z.object({ nannyUserId: z.string().min(1) }).parse(req.body)
    const result = await favoritesService.toggle(req.user!.userId, nannyUserId)
    ok(res, result)
  },

  async list(req: Request, res: Response): Promise<void> {
    const favorites = await favoritesService.list(req.user!.userId)
    ok(res, { favorites })
  },

  async check(req: Request, res: Response): Promise<void> {
    const result = await favoritesService.check(req.user!.userId, req.params.nannyUserId)
    ok(res, result)
  },
}
