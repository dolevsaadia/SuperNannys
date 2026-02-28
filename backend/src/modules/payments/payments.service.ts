import { config } from '../../config'
import { AppError } from '../../shared/errors/app-error'
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
