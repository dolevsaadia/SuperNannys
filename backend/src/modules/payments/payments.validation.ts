import { z } from 'zod'

export const createIntentSchema = z.object({
  bookingId: z.string(),
})

export const addPaymentMethodSchema = z.object({
  stripePaymentMethodId: z.string(),
  last4: z.string().optional(),
  brand: z.string().optional(),
  expiryMonth: z.number().optional(),
  expiryYear: z.number().optional(),
  isDefault: z.boolean().optional(),
})

export type CreateIntentInput = z.infer<typeof createIntentSchema>
export type AddPaymentMethodInput = z.infer<typeof addPaymentMethodSchema>
