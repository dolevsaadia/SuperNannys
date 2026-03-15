import { z } from 'zod'

export const searchNanniesSchema = z.object({
  city: z.string().optional(),
  minRate: z.string().optional(),
  maxRate: z.string().optional(),
  minYears: z.string().optional(),
  language: z.string().optional(),
  skill: z.string().optional(),
  minRating: z.string().optional(),
  lat: z.string().optional(),
  lng: z.string().optional(),
  radiusKm: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
  sortBy: z.string().optional(),
  hasRecurringRate: z.string().optional(),
})

export const updateNannyProfileSchema = z.object({
  headline: z.string().max(200).optional(),
  bio: z.string().max(2000).optional(),
  hourlyRateNis: z.number().min(20).max(500).optional(),
  recurringHourlyRateNis: z.number().min(20).max(500).optional().nullable(),
  yearsExperience: z.number().min(0).max(50).optional(),
  languages: z.array(z.string()).optional(),
  skills: z.array(z.string()).optional(),
  city: z.string().optional(),
  address: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  isAvailable: z.boolean().optional(),
  // New fields
  minimumHoursPerBooking: z.number().min(0).max(8).optional(),
  allowsBabysittingAtHome: z.boolean().optional(),
  streetName: z.string().optional(),
  houseNumber: z.string().optional(),
  postalCode: z.string().optional(),
  apartmentFloor: z.string().optional(),
  availability: z.array(z.object({
    dayOfWeek: z.number().min(0).max(6),
    fromTime: z.string(),
    toTime: z.string(),
    isAvailable: z.boolean(),
  })).optional(),
})

// ── Date availability schemas ─────────────────────────────
const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/

export const dateAvailabilitySchema = z.object({
  date: z.string().refine(v => !isNaN(Date.parse(v)), { message: 'Invalid date format' }),
  startTime: z.string().regex(timeRegex, 'Invalid time format. Expected HH:mm'),
  endTime: z.string().regex(timeRegex, 'Invalid time format. Expected HH:mm'),
  isBlocked: z.boolean().optional(),
})

export const blockDateSchema = z.object({
  date: z.string().refine(v => !isNaN(Date.parse(v)), { message: 'Invalid date format' }),
})

export type SearchNanniesInput = z.infer<typeof searchNanniesSchema>
export type UpdateNannyProfileInput = z.infer<typeof updateNannyProfileSchema>
