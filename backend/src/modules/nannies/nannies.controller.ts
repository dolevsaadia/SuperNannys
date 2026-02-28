import { Request, Response } from 'express'
import { ok } from '../../shared/utils/response'
import { nanniesService } from './nannies.service'
import { searchNanniesSchema, updateNannyProfileSchema } from './nannies.validation'

export const nanniesController = {
  async search(req: Request, res: Response): Promise<void> {
    const params = searchNanniesSchema.parse(req.query)
    const result = await nanniesService.search(params)
    ok(res, result)
  },

  async getMyProfile(req: Request, res: Response): Promise<void> {
    const profile = await nanniesService.getMyProfile(req.user!.userId)
    ok(res, profile)
  },

  async getById(req: Request, res: Response): Promise<void> {
    const result = await nanniesService.getById(req.params.id)
    ok(res, result)
  },

  async updateMyProfile(req: Request, res: Response): Promise<void> {
    const data = updateNannyProfileSchema.parse(req.body)
    const profile = await nanniesService.updateMyProfile(req.user!.userId, data)
    ok(res, profile)
  },
}
