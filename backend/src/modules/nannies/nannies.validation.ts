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
})

export const updateNannyProfileSchema = z.object({
  headline: z.string().max(200).optional(),
  bio: z.string().max(2000).optional(),
  hourlyRateNis: z.number().min(20).max(500).optional(),
  yearsExperience: z.number().min(0).max(50).optional(),
  languages: z.array(z.string()).optional(),
  skills: z.array(z.string()).optional(),
  city: z.string().optional(),
  address: z.string().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  isAvailable: z.boolean().optional(),
  availability: z.array(z.object({
    dayOfWeek: z.number().min(0).max(6),
    fromTime: z.string(),
    toTime: z.string(),
    isAvailable: z.boolean(),
  })).optional(),
})

export type SearchNanniesInput = z.infer<typeof searchNanniesSchema>
export type UpdateNannyProfileInput = z.infer<typeof updateNannyProfileSchema>
