import { prisma } from '../../db'
import { AppError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { verificationRequestsDal } from './verification.dal'

export const verificationService = {
  async submit(userId: string, data: { idCardUrl?: string; idAppendixUrl?: string; policeClearanceUrl?: string }) {
    // Check if there's already a pending request
    const existing = await verificationRequestsDal.findByUserId(userId)
    if (existing && existing.status === 'pending') {
      throw new AppError('You already have a pending verification request', 400)
    }

    return verificationRequestsDal.create({ userId, ...data })
  },

  async getMyRequest(userId: string) {
    return verificationRequestsDal.findByUserId(userId)
  },

  async getAll(status?: string) {
    return verificationRequestsDal.findAll(status)
  },

  async review(requestId: string, adminUserId: string, status: string, adminNotes?: string) {
    const request = await verificationRequestsDal.findById(requestId)
    if (!request) throw new AppError('Verification request not found', 404)

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
