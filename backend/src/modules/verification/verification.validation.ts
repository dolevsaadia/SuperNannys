import { z } from 'zod'

export const submitVerificationSchema = z.object({
  idCardUrl: z.string().url().optional(),
  idAppendixUrl: z.string().url().optional(),
  policeClearanceUrl: z.string().url().optional(),
}).refine(
  (data) => data.idCardUrl || data.idAppendixUrl || data.policeClearanceUrl,
  { message: 'At least one document URL must be provided' },
)

export const reviewVerificationSchema = z.object({
  status: z.enum(['approved', 'rejected', 'needs_info']),
  adminNotes: z.string().max(1000).optional(),
})

export const getAllVerificationSchema = z.object({
  status: z.enum(['pending', 'approved', 'rejected', 'needs_info']).optional(),
})
