import { prisma } from '../../db'
import { AppError, NotFoundError, ConflictError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { verificationRequestsDal } from './verification.dal'

export const verificationService = {
  async submit(userId: string, data: { idCardUrl?: string; idAppendixUrl?: string; policeClearanceUrl?: string }) {
    // Check if there's already a pending request
    const existing = await verificationRequestsDal.findByUserId(userId)
    if (existing && existing.status === 'pending') {
      throw new ConflictError('You already have a pending verification request')
    }

    return verificationRequestsDal.create({ userId, ...data })
  },

  async update(userId: string, data: { idCardUrl?: string; idAppendixUrl?: string; policeClearanceUrl?: string }) {
    const existing = await verificationRequestsDal.findByUserId(userId)
    if (!existing) {
      throw new NotFoundError('No verification request found. Please submit a new one.')
    }
    if (existing.status === 'approved') {
      throw new ConflictError('Your verification is already approved and cannot be modified.')
    }

    // Merge: keep existing URLs for fields not provided in this update
    const merged = {
      idCardUrl: data.idCardUrl ?? existing.idCardUrl ?? undefined,
      idAppendixUrl: data.idAppendixUrl ?? existing.idAppendixUrl ?? undefined,
      policeClearanceUrl: data.policeClearanceUrl ?? existing.policeClearanceUrl ?? undefined,
    }

    return verificationRequestsDal.updateRequest(existing.id, merged)
  },

  async getMyRequest(userId: string) {
    return verificationRequestsDal.findByUserId(userId)
  },

  async getAll(status?: string) {
    return verificationRequestsDal.findAll(status)
  },

  async review(requestId: string, adminUserId: string, status: string, adminNotes?: string) {
    const request = await verificationRequestsDal.findById(requestId)
    if (!request) throw new NotFoundError('Verification request')

    const updated = await verificationRequestsDal.updateStatus(requestId, {
      status,
      adminNotes,
      reviewedBy: adminUserId,
    })

    // If approved, mark user as verified
    if (status === 'approved') {
      await prisma.user.update({
        where: { id: request.userId },
        data: { isVerified: true },
      })
      logger.info('User verified via admin review', { userId: request.userId, requestId })
    }

    return updated
  },
}
