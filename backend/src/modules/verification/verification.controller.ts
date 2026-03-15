import type { Request, Response } from 'express'
import { verificationService } from './verification.service'
import { submitVerificationSchema, reviewVerificationSchema, getAllVerificationSchema } from './verification.validation'

export const verificationController = {
  async submit(req: Request, res: Response) {
    const data = submitVerificationSchema.parse(req.body)
    const result = await verificationService.submit(req.user!.userId, data)
    res.status(201).json({ data: result })
  },

  async getMyRequest(req: Request, res: Response) {
    const result = await verificationService.getMyRequest(req.user!.userId)
    res.json({ data: result })
  },

  async getAll(req: Request, res: Response) {
    const { status } = getAllVerificationSchema.parse(req.query)
    const result = await verificationService.getAll(status)
    res.json({ data: result })
  },

  async review(req: Request, res: Response) {
    const { status, adminNotes } = reviewVerificationSchema.parse(req.body)
    const result = await verificationService.review(req.params.id, req.user!.userId, status, adminNotes)
    res.json({ data: result })
  },
}
