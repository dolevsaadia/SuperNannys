import { Request, Response } from 'express'
import { ok, created } from '../../shared/utils/response'
import { paymentsService } from './payments.service'
import { createIntentSchema, addPaymentMethodSchema } from './payments.validation'

export const paymentsController = {
  async createIntent(req: Request, res: Response): Promise<void> {
    const { bookingId } = createIntentSchema.parse(req.body)
    const result = await paymentsService.createIntent(req.user!.userId, bookingId)
    ok(res, result)
  },

  async handleWebhook(req: Request, res: Response): Promise<void> {
    const sig = req.headers['stripe-signature'] as string
    try {
      const result = await paymentsService.handleWebhook(req.body, sig)
      res.json(result)
    } catch {
      res.status(400).json({ error: 'Webhook signature verification failed' })
    }
  },

  async getPaymentMethods(req: Request, res: Response): Promise<void> {
    const methods = await paymentsService.getPaymentMethods(req.user!.userId)
    ok(res, methods)
  },

  async addPaymentMethod(req: Request, res: Response): Promise<void> {
    const data = addPaymentMethodSchema.parse(req.body)
    const method = await paymentsService.addPaymentMethod(req.user!.userId, data)
    created(res, method)
  },
}
