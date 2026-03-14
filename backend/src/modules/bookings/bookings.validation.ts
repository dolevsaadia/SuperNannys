import { z } from 'zod'

export const createBookingSchema = z.object({
  nannyUserId: z.string(),
  startTime: z.string().datetime(),
  endTime: z.string().datetime(),
  notes: z.string().max(500).optional(),
  childrenCount: z.number().int().min(1).max(10).default(1),
  childrenAges: z.array(z.string()).optional(),
  address: z.string().optional(),
  // Structured address fields
  bookingCity: z.string().optional(),
  bookingStreet: z.string().optional(),
  bookingHouseNum: z.string().optional(),
  bookingPostalCode: z.string().optional(),
  bookingLat: z.number().optional(),
  bookingLng: z.number().optional(),
  locationType: z.enum(['parent_home', 'nanny_home']).optional(),
})

export const updateBookingStatusSchema = z.object({
  status: z.enum(['ACCEPTED', 'DECLINED', 'CANCELLED']),
})

export type CreateBookingInput = z.infer<typeof createBookingSchema>
export type UpdateBookingStatusInput = z.infer<typeof updateBookingStatusSchema>
