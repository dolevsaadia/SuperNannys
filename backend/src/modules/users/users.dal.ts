import { prisma } from '../../db'
import type { UpdateProfileInput, RegisterDeviceInput } from './users.validation'

export const usersDal = {
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
