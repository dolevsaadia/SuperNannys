import { prisma } from '../../db'

export const messagesDal = {
  /**
   * Returns ONE conversation per other-user by finding all bookings,
   * then deduplicating: keep only the booking with the most recent message
   * (or most recently updated) per unique counterpart.
   */
  async getConversations(userId: string, role: string) {
    const isParent = role === 'PARENT'

    // Get hidden user IDs for this user
    const hiddenUserIds = await this.getHiddenUserIds(userId)

    const bookings = await prisma.booking.findMany({
      where: isParent ? { parentUserId: userId } : { nannyUserId: userId },
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

    // Deduplicate: one conversation per other user
    // Keep the booking with the newest message (or newest updatedAt if no messages)
    const seen = new Map<string, typeof bookings[0]>()
    // Track aggregate unread counts across ALL bookings with same user
    const unreadByUser = new Map<string, number>()

    for (const b of bookings) {
      const otherUserId = isParent ? b.nannyUserId : b.parentUserId

      // Skip hidden conversations
      if (hiddenUserIds.includes(otherUserId)) continue

      const unread = (b._count?.messages ?? 0)
      unreadByUser.set(otherUserId, (unreadByUser.get(otherUserId) ?? 0) + unread)

      if (!seen.has(otherUserId)) {
        seen.set(otherUserId, b)
      } else {
        // Replace if this booking has a more recent message
        const existing = seen.get(otherUserId)!
        const existingMsgTime = existing.messages[0]?.createdAt ?? existing.updatedAt
        const thisMsgTime = b.messages[0]?.createdAt ?? b.updatedAt
        if (thisMsgTime > existingMsgTime) {
          seen.set(otherUserId, b)
        }
      }
    }

    // Patch the _count with aggregate unread across all bookings with same user
    return [...seen.entries()].map(([otherUserId, booking]) => ({
      ...booking,
      _count: { messages: unreadByUser.get(otherUserId) ?? 0 },
    }))
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

  /** Get list of otherUserIds that this user has hidden */
  async getHiddenUserIds(userId: string): Promise<string[]> {
    const hides = await prisma.chatHide.findMany({
      where: { userId },
      select: { otherUserId: true },
    })
    return hides.map(h => h.otherUserId)
  },

  /** Hide a conversation (by other user) for the current user */
  hideConversation(userId: string, otherUserId: string) {
    return prisma.chatHide.upsert({
      where: { userId_otherUserId: { userId, otherUserId } },
      create: { userId, otherUserId },
      update: {},
    })
  },

  /** Unhide a conversation (if needed in the future) */
  unhideConversation(userId: string, otherUserId: string) {
    return prisma.chatHide.deleteMany({
      where: { userId, otherUserId },
    })
  },
}
