import { z } from 'zod'

export const updateProfileSchema = z.object({
  fullName: z.string().min(2).max(100).optional(),
  phone: z.string().optional(),
  avatarUrl: z.string().url().optional().or(z.literal('')),
})

export const registerDeviceSchema = z.object({
  fcmToken: z.string().min(1),
  platform: z.enum(['ios', 'android']),
})

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>
export type RegisterDeviceInput = z.infer<typeof registerDeviceSchema>
