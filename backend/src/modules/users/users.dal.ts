import { prisma } from '../../db'
import { logger } from '../../shared/utils/logger'
import type { UpdateProfileInput, RegisterDeviceInput } from './users.validation'

export const usersDal = {
  /**
   * Soft-delete a user account in a single atomic transaction:
   * 1. Set isActive=false, deletedAt=now, anonymise PII
   * 2. Cancel future REQUESTED / ACCEPTED bookings
   * 3. Cancel PENDING / ACTIVE recurring bookings
   */
  async softDeleteUser(userId: string, adminUserId?: string) {
    return prisma.$transaction(async (tx) => {
      const now = new Date()

      // 0. Read original name/email before anonymizing
      const original = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { fullName: true, email: true },
      })

      // 1. Deactivate + anonymise, preserving pre-delete info
      await tx.user.update({
        where: { id: userId },
        data: {
          isActive: false,
          deletedAt: now,
          deletedByAdminId: adminUserId ?? null,
          preDeleteName: original.fullName,
          preDeleteEmail: original.email,
          fullName: 'Deleted User',
          avatarUrl: null,
          phone: null,
          email: `deleted_${userId}@deleted.local`,
          idNumber: null,
          dateOfBirth: null,
          googleSub: null,
          passwordHash: null,
        },
      })

      // 2. Cancel future bookings (as parent or nanny)
      const cancelledBookings = await tx.booking.updateMany({
        where: {
          OR: [{ parentUserId: userId }, { nannyUserId: userId }],
          status: { in: ['REQUESTED', 'ACCEPTED'] },
          startTime: { gt: now },
        },
        data: { status: 'CANCELLED' },
      })

      // 3. Cancel active recurring bookings
      const cancelledRecurring = await tx.recurringBooking.updateMany({
        where: {
          OR: [{ parentUserId: userId }, { nannyUserId: userId }],
          status: { in: ['PENDING', 'ACTIVE'] },
        },
        data: { status: 'CANCELLED' },
      })

      // 4. Remove devices (no push to deleted user)
      await tx.device.deleteMany({ where: { userId } })

      // 5. Remove favorites in both directions
      await tx.favorite.deleteMany({
        where: { OR: [{ userId }, { nannyUserId: userId }] },
      })

      logger.info('User soft-deleted', {
        userId,
        cancelledBookings: cancelledBookings.count,
        cancelledRecurring: cancelledRecurring.count,
      })

      return { cancelledBookings: cancelledBookings.count, cancelledRecurring: cancelledRecurring.count }
    })
  },

  updateUser(userId: string, data: UpdateProfileInput) {
    return prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, email: true, fullName: true, phone: true, avatarUrl: true, role: true },
    })
  },

  getNotifications(userId: string, skip: number, take: number) {
    return prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    })
  },

  countUnreadNotifications(userId: string) {
    return prisma.notification.count({ where: { userId, isRead: false } })
  },

  markAllNotificationsRead(userId: string) {
    return prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    })
  },

  upsertDevice(userId: string, data: RegisterDeviceInput) {
    return prisma.device.upsert({
      where: { fcmToken: data.fcmToken },
      update: { userId },
      create: { userId, ...data },
    })
  },

  getEarnings(userId: string) {
    return prisma.earning.findMany({
      where: { nannyUserId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        booking: {
          select: {
            startTime: true, endTime: true,
            parent: { select: { fullName: true, avatarUrl: true } },
          },
        },
      },
    })
  },
}
