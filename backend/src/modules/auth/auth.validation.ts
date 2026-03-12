import { z } from 'zod'

export const registerSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  fullName: z.string().min(2).max(100),
  phone: z.string().optional(),
  idNumber: z.string().min(5).max(9).optional(),
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

export const verifyOTPSchema = z.object({
  email: z.string().email(),
  code: z.string().length(6, 'Code must be 6 digits'),
})

export const resendOTPSchema = z.object({
  email: z.string().email(),
})

export type RegisterInput = z.infer<typeof registerSchema>
export type LoginInput = z.infer<typeof loginSchema>
export type GoogleSignInInput = z.infer<typeof googleSignInSchema>
export type VerifyOTPInput = z.infer<typeof verifyOTPSchema>
export type ResendOTPInput = z.infer<typeof resendOTPSchema>
