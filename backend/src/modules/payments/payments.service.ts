import { config } from '../../config'
import { AppError, NotFoundError, ForbiddenError, BadRequestError, ConflictError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { paymentsDal } from './payments.dal'
import type { AddPaymentMethodInput } from './payments.validation'

/** Cached Stripe instance — lazy-initialised on first use. */
let stripeInstance: any = null

async function getStripe() {
  if (!stripeInstance) {
    const Stripe = (await import('stripe')).default
    stripeInstance = new Stripe(config.payments.stripeSecretKey)
  }
  return stripeInstance
}

export const paymentsService = {
  async createIntent(userId: string, bookingId: string) {
    const booking = await paymentsDal.findBookingById(bookingId)
    if (!booking) throw new NotFoundError('Booking')
    if (booking.parentUserId !== userId) throw new ForbiddenError()
    if (booking.isPaid) throw new ConflictError('Booking already paid')

    const stripe = await getStripe()

    const intent = await stripe.paymentIntents.create({
      amount: booking.totalAmountNis * 100, // agorot
      currency: 'ils',
      metadata: { bookingId: booking.id },
      automatic_payment_methods: { enabled: true },
    })

    await paymentsDal.updateBookingPaymentIntent(booking.id, intent.id)

    logger.info('Payment intent created', { bookingId, userId, amount: booking.totalAmountNis })

    return {
      clientSecret: intent.client_secret,
      publishableKey: config.payments.stripePublishableKey,
      amount: booking.totalAmountNis,
    }
  },

  /**
   * Charge the parent after the session ends using their saved payment method.
   * Uses Stripe off_session PaymentIntent with a saved customer/payment method.
   */
  async chargeAfterSession(bookingId: string, amountNis: number) {
    if (!config.payments.enabled) {
      logger.info('Payments disabled — skipping charge', { bookingId, amount: amountNis })
      return null
    }

    const booking = await paymentsDal.findBookingById(bookingId)
    if (!booking) throw new NotFoundError('Booking')
    if (booking.isPaid) {
      logger.info('Booking already paid — skipping', { bookingId })
      return null
    }

    // Find the parent's default payment method
    const paymentMethods = await paymentsDal.getPaymentMethods(booking.parentUserId)
    const defaultMethod = paymentMethods.find(pm => pm.isDefault) || paymentMethods[0]

    if (!defaultMethod?.stripePaymentMethodId) {
      logger.error('No payment method found for parent — cannot charge', {
        parentUserId: booking.parentUserId,
        bookingId,
      })
      // TODO: send push notification to parent to add payment method
      return null
    }

    try {
      const stripe = await getStripe()

      const intent = await stripe.paymentIntents.create({
        amount: amountNis * 100, // agorot
        currency: 'ils',
        payment_method: defaultMethod.stripePaymentMethodId,
        confirm: true,
        off_session: true,
        metadata: {
          bookingId: booking.id,
          type: 'post_session',
        },
      })

      await paymentsDal.updateBookingPaymentIntent(booking.id, intent.id)

      if (intent.status === 'succeeded') {
        await paymentsDal.markBookingPaid(intent.id)
        logger.info('Post-session charge succeeded', { bookingId, amount: amountNis, paymentIntentId: intent.id })
      }

      return { paymentIntentId: intent.id, status: intent.status }
    } catch (err: any) {
      logger.error('Post-session charge failed', { bookingId, amount: amountNis, error: err.message })
      // Don't throw — the session is still completed, payment can be retried
      return { error: err.message }
    }
  },

  async handleWebhook(rawBody: Buffer, signature: string) {
    if (!signature) {
      throw new BadRequestError('Missing Stripe signature header')
    }

    const stripe = await getStripe()

    let event: any
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, config.payments.stripeWebhookSecret)
    } catch (err: any) {
      logger.error('Stripe webhook signature verification failed', { error: err.message })
      throw new BadRequestError('Invalid webhook signature')
    }

    logger.info('Stripe webhook received', { type: event.type })

    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object as { id: string }
      try {
        await paymentsDal.markBookingPaid(intent.id)
        logger.info('Booking marked as paid', { paymentIntentId: intent.id })
      } catch (err) {
        logger.error('Failed to mark booking as paid', { paymentIntentId: intent.id, err })
      }
    }

    return { received: true }
  },

  async getPaymentMethods(userId: string) {
    return paymentsDal.getPaymentMethods(userId)
  },

  async addPaymentMethod(userId: string, data: AddPaymentMethodInput) {
    if (data.isDefault) {
      await paymentsDal.clearDefaultPaymentMethods(userId)
    }
    const method = await paymentsDal.createPaymentMethod(userId, data)
    logger.info('Payment method added', { userId, isDefault: data.isDefault })
    return method
  },
}
