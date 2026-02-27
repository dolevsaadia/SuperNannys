import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, created, fail, notFound } from '../utils/response'
import { requireAuth } from '../middlewares/auth.middleware'
import { config } from '../config'

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

// POST /api/payments/intent
router.post('/intent', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({ bookingId: z.string() }).safeParse(req.body)
  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const booking = await prisma.booking.findUnique({ where: { id: parse.data.bookingId } })
  if (!booking) { notFound(res, 'Booking not found'); return }
  if (booking.parentUserId !== req.user!.userId) { fail(res, 'Not authorized', 403); return }
  if (booking.isPaid) { fail(res, 'Booking already paid'); return }

  const Stripe = (await import('stripe')).default
  const stripe = new Stripe(config.payments.stripeSecretKey)

  const intent = await stripe.paymentIntents.create({
    amount: booking.totalAmountNis * 100, // agorot
    currency: 'ils',
    metadata: { bookingId: booking.id },
    automatic_payment_methods: { enabled: true },
  })

  await prisma.booking.update({ where: { id: booking.id }, data: { paymentIntentId: intent.id } })

  ok(res, {
    clientSecret: intent.client_secret,
    publishableKey: config.payments.stripePublishableKey,
    amount: booking.totalAmountNis,
  })
})

// POST /api/payments/webhook  (raw body)
router.post('/webhook', async (req: Request, res: Response): Promise<void> => {
  const Stripe = (await import('stripe')).default
  const stripe = new Stripe(config.payments.stripeSecretKey)
  const sig = req.headers['stripe-signature'] as string

  let event
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, config.payments.stripeWebhookSecret)
  } catch {
    res.status(400).json({ error: 'Webhook signature verification failed' })
    return
  }

  if (event.type === 'payment_intent.succeeded') {
    const intent = event.data.object as { id: string }
    await prisma.booking.updateMany({
      where: { paymentIntentId: intent.id },
      data: { isPaid: true },
    })
  }

  res.json({ received: true })
})

// GET /api/payments/methods
router.get('/methods', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const methods = await prisma.paymentMethod.findMany({
    where: { userId: req.user!.userId },
    orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
  })
  ok(res, methods)
})

// POST /api/payments/methods
router.post('/methods', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({
    stripePaymentMethodId: z.string(),
    last4: z.string().optional(),
    brand: z.string().optional(),
    expiryMonth: z.number().optional(),
    expiryYear: z.number().optional(),
    isDefault: z.boolean().optional(),
  }).safeParse(req.body)

  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  if (parse.data.isDefault) {
    await prisma.paymentMethod.updateMany({ where: { userId: req.user!.userId }, data: { isDefault: false } })
  }

  const method = await prisma.paymentMethod.create({
    data: { userId: req.user!.userId, ...parse.data },
  })
  created(res, method)
})

export default router
