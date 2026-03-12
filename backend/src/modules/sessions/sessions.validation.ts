import { z } from 'zod'

export const confirmStartSchema = z.object({
  // no body needed — bookingId comes from URL param
}).optional()

export const requestEndSchema = z.object({
  // no body needed
}).optional()

export const confirmEndSchema = z.object({
  // no body needed
}).optional()
