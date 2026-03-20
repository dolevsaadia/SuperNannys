import { z } from 'zod'

export const updateProfileSchema = z.object({
  fullName: z.string().min(2).max(100).optional(),
  phone: z.string().max(20).optional(),
  idNumber: z.string().min(5).max(9).optional(),
  avatarUrl: z.string().url().optional().or(z.literal('')),
  city: z.string().max(100).optional(),
  streetName: z.string().max(200).optional(),
  houseNumber: z.string().max(20).optional(),
  postalCode: z.string().max(10).optional(),
  apartmentFloor: z.string().max(20).optional(),
})

export const registerDeviceSchema = z.object({
  fcmToken: z.string().min(1),
  platform: z.enum(['ios', 'android']),
})

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>
export type RegisterDeviceInput = z.infer<typeof registerDeviceSchema>
