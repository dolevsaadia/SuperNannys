import { z } from 'zod'

export const registerSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  fullName: z.string().min(2).max(100),
  phone: z.string().optional(),
  role: z.enum(['PARENT', 'NANNY']),
})

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

export const googleSignInSchema = z.object({
  idToken: z.string().min(1, 'idToken is required'),
  role: z.enum(['PARENT', 'NANNY']).optional(),
})

export type RegisterInput = z.infer<typeof registerSchema>
export type LoginInput = z.infer<typeof loginSchema>
export type GoogleSignInInput = z.infer<typeof googleSignInSchema>
