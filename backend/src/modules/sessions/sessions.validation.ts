import { z } from 'zod'

/** Validates that bookingId URL param is a non-empty string */
export const bookingIdParamSchema = z.object({
  bookingId: z.string().min(1, 'bookingId is required'),
})
