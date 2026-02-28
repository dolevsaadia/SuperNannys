import { Request, Response } from 'express'
import { ok, created } from '../../shared/utils/response'
import { reviewsService } from './reviews.service'
import { createReviewSchema } from './reviews.validation'

export const reviewsController = {
  async create(req: Request, res: Response): Promise<void> {
    const data = createReviewSchema.parse(req.body)
    const review = await reviewsService.create(req.user!.userId, data)
    created(res, review)
  },

  async getByNanny(req: Request, res: Response): Promise<void> {
    const { page = '1', limit = '10' } = req.query as Record<string, string>
    const pageNum = Math.max(1, parseInt(page))
    const limitNum = Math.min(50, parseInt(limit))
    const result = await reviewsService.getByNanny(req.params.userId, pageNum, limitNum)
    ok(res, result)
  },
}
