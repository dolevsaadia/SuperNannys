import { z } from 'zod'

const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/

export const createRecurringBookingSchema = z.object({
  nannyUserId: z.string(),
  daysOfWeek: z.array(z.number().int().min(0).max(6)).min(1).max(7),
  startTime: z.string().regex(timeRegex, 'Must be HH:mm format'),
  endTime: z.string().regex(timeRegex, 'Must be HH:mm format'),
  startDate: z.string().datetime(),
  endDate: z.string().datetime().optional(),
  childrenCount: z.number().int().min(1).max(10).default(1),
  childrenAges: z.array(z.string()).optional(),
  address: z.string().optional(),
  notes: z.string().max(500).optional(),
}).refine(
  (data) => data.startTime < data.endTime,
  { message: 'endTime must be after startTime', path: ['endTime'] },
)

export const updateRecurringBookingSchema = z.object({
  daysOfWeek: z.array(z.number().int().min(0).max(6)).min(1).max(7).optional(),
  startTime: z.string().regex(timeRegex, 'Must be HH:mm format').optional(),
  endTime: z.string().regex(timeRegex, 'Must be HH:mm format').optional(),
  endDate: z.string().datetime().optional().nullable(),
  childrenCount: z.number().int().min(1).max(10).optional(),
  childrenAges: z.array(z.string()).optional(),
  address: z.string().optional(),
  notes: z.string().max(500).optional(),
})

export const updateStatusSchema = z.object({
  status: z.enum(['ACTIVE', 'PAUSED', 'CANCELLED', 'ENDED']),
})

export type CreateRecurringBookingInput = z.infer<typeof createRecurringBookingSchema>
export type UpdateRecurringBookingInput = z.infer<typeof updateRecurringBookingSchema>
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>
