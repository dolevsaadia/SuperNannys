import { prisma } from '../../db'

export const messagesDal = {
  getConversations(userId: string, role: string) {
    return prisma.booking.findMany({
      where: role === 'PARENT' ? { parentUserId: userId } : { nannyUserId: userId },
      orderBy: { updatedAt: 'desc' },
      include: {
        parent: { select: { id: true, fullName: true, avatarUrl: true } },
        nanny: { select: { id: true, fullName: true, avatarUrl: true } },
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        _count: {
          select: { messages: { where: { isRead: false, fromUserId: { not: userId } } } },
        },
      },
    })
  },

  getMessages(bookingId: string, skip: number, take: number) {
    return prisma.message.findMany({
      where: { bookingId },
      orderBy: { createdAt: 'asc' },
      skip,
      take,
      include: { from: { select: { id: true, fullName: true, avatarUrl: true } } },
    })
  },

  countMessages(bookingId: string) {
    return prisma.message.count({ where: { bookingId } })
  },

  markAsRead(bookingId: string, excludeUserId: string) {
    return prisma.message.updateMany({
      where: { bookingId, fromUserId: { not: excludeUserId }, isRead: false },
      data: { isRead: true },
    })
  },

  createMessage(bookingId: string, fromUserId: string, text: string) {
    return prisma.message.create({
      data: { bookingId, fromUserId, text },
      include: { from: { select: { id: true, fullName: true, avatarUrl: true } } },
    })
  },

  findBookingById(bookingId: string) {
    return prisma.booking.findUnique({ where: { id: bookingId } })
  },
}
