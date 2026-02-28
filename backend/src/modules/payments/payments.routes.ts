import { Router, Request, Response } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { config } from '../../config'
import { paymentsController } from './payments.controller'

const router = Router()

// Feature flag gate — returns 503 when payments are not configured
router.use((_req: Request, res: Response, next: () => void) => {
  if (!config.payments.enabled) {
    res.status(503).json({
      success: false,
      message: 'Payments feature is not enabled. Set ENABLE_PAYMENTS=true in .env and add your Stripe keys.',
    })
    return
  }
  next()
})

router.post('/intent',   requireAuth, asyncHandler(paymentsController.createIntent))
router.post('/webhook',  asyncHandler(paymentsController.handleWebhook))
router.get('/methods',   requireAuth, asyncHandler(paymentsController.getPaymentMethods))
router.post('/methods',  requireAuth, asyncHandler(paymentsController.addPaymentMethod))

export default router
