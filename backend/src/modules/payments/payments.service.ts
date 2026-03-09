import { config } from '../../config'
import { AppError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { paymentsDal } from './payments.dal'
import type { AddPaymentMethodInput } from './payments.validation'

export const paymentsService = {
  async createIntent(userId: string, bookingId: string) {
    const booking = await paymentsDal.findBookingById(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)
    if (booking.parentUserId !== userId) throw new AppError('Not authorized', 403)
    if (booking.isPaid) throw new AppError('Booking already paid')

    const Stripe = (await import('stripe')).default
    const stripe = new Stripe(config.payments.stripeSecretKey)

    const intent = await stripe.paymentIntents.create({
      amount: booking.totalAmountNis * 100, // agorot
      currency: 'ils',
      metadata: { bookingId: booking.id },
      automatic_payment_methods: { enabled: true },
    })

    await paymentsDal.updateBookingPaymentIntent(booking.id, intent.id)

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
      logger.info(`Payments disabled — skipping charge for booking ${bookingId} (₪${amountNis})`)
      return null
    }

    const booking = await paymentsDal.findBookingById(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)
    if (booking.isPaid) {
      logger.info(`Booking ${bookingId} already paid — skipping`)
      return null
    }

    // Find the parent's default payment method
    const paymentMethods = await paymentsDal.getPaymentMethods(booking.parentUserId)
    const defaultMethod = paymentMethods.find(pm => pm.isDefault) || paymentMethods[0]

    if (!defaultMethod?.stripePaymentMethodId) {
      logger.warn(`No payment method found for parent ${booking.parentUserId} — booking ${bookingId}`)
      // TODO: send push notification to parent to add payment method
      return null
    }

    try {
      const Stripe = (await import('stripe')).default
      const stripe = new Stripe(config.payments.stripeSecretKey)

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
        logger.info(`Post-session charge succeeded: booking ${bookingId}, ₪${amountNis}`)
      }

      return { paymentIntentId: intent.id, status: intent.status }
    } catch (err: any) {
      logger.error(`Post-session charge failed: booking ${bookingId}`, { err: err.message })
      // Don't throw — the session is still completed, payment can be retried
      return { error: err.message }
    }
  },

  async handleWebhook(rawBody: Buffer, signature: string) {
    const Stripe = (await import('stripe')).default
    const stripe = new Stripe(config.payments.stripeSecretKey)

    const event = stripe.webhooks.constructEvent(rawBody, signature, config.payments.stripeWebhookSecret)

    if (event.type === 'payment_intent.succeeded') {
      const intent = event.data.object as { id: string }
      await paymentsDal.markBookingPaid(intent.id)
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
    return paymentsDal.createPaymentMethod(userId, data)
  },
}
