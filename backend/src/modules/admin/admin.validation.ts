import { z } from 'zod'

export const updateUserSchema = z.object({
  isActive: z.boolean().optional(),
  isVerified: z.boolean().optional(),
  role: z.enum(['PARENT', 'NANNY', 'ADMIN']).optional(),
})

export type UpdateUserInput = z.infer<typeof updateUserSchema>
