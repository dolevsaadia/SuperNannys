import { Prisma } from '@prisma/client'
import { usersDal } from './users.dal'
import { ConflictError, NotFoundError, ForbiddenError } from '../../shared/errors/app-error'
import { authDal } from '../auth/auth.dal'
import { logger } from '../../shared/utils/logger'
import type { UpdateProfileInput, RegisterDeviceInput } from './users.validation'
import type { PaginationParams } from '../../shared/utils/pagination'

export const usersService = {
  /** Self-service account deletion (soft delete). */
  async deleteAccount(userId: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new NotFoundError('User')
    if (user.deletedAt) throw new ForbiddenError('Account is already deleted')

    const result = await usersDal.softDeleteUser(userId)
    logger.info('Account self-deleted', { userId, ...result })
    return { message: 'Account deleted successfully' }
  },

  async updateProfile(userId: string, data: UpdateProfileInput) {
    try {
      return await usersDal.updateUser(userId, data)
    } catch (err) {
      // Prisma P2002 = unique constraint violation — give a human-readable message
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        const target = (err.meta?.target as string[]) ?? []
        if (target.includes('idNumber')) {
          throw new ConflictError('This ID number is already registered to another account. Please check and try again.')
        }
        if (target.includes('email')) {
          throw new ConflictError('This email is already registered to another account.')
        }
        if (target.includes('phone')) {
          throw new ConflictError('This phone number is already registered to another account.')
        }
        throw new ConflictError('A record with this data already exists.')
      }
      throw err
    }
  },

  async getNotifications(userId: string, pagination: PaginationParams) {
    const [notifications, unreadCount] = await Promise.all([
      usersDal.getNotifications(userId, pagination.skip, pagination.limit),
      usersDal.countUnreadNotifications(userId),
    ])
    return { notifications, unreadCount, pagination: { page: pagination.page, limit: pagination.limit } }
  },

  async markAllNotificationsRead(userId: string) {
    await usersDal.markAllNotificationsRead(userId)
    return { message: 'All notifications marked as read' }
  },

  async registerDevice(userId: string, data: RegisterDeviceInput) {
    await usersDal.upsertDevice(userId, data)
    return { message: 'Device registered' }
  },

  async getEarnings(userId: string) {
    const earnings = await usersDal.getEarnings(userId)
    const totalEarned = earnings.reduce((s, e) => s + e.netAmountNis, 0)
    const totalPending = earnings.filter(e => !e.isPaid).reduce((s, e) => s + e.netAmountNis, 0)
    return { earnings, summary: { totalEarned, totalPending, totalJobs: earnings.length } }
  },
}
