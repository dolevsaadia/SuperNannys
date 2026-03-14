import type { Request, Response } from 'express'
import { verificationService } from './verification.service'

export const verificationController = {
  async submit(req: Request, res: Response) {
    const result = await verificationService.submit(req.user!.userId, req.body)
    res.status(201).json({ data: result })
  },

  async getMyRequest(req: Request, res: Response) {
    const result = await verificationService.getMyRequest(req.user!.userId)
    res.json({ data: result })
  },

  async getAll(req: Request, res: Response) {
    const status = req.query.status as string | undefined
    const result = await verificationService.getAll(status)
    res.json({ data: result })
  },

  async review(req: Request, res: Response) {
    const { status, adminNotes } = req.body
    const result = await verificationService.review(req.params.id, req.user!.userId, status, adminNotes)
    res.json({ data: result })
  },
}
