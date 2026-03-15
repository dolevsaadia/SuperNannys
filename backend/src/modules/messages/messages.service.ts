import { AppError, NotFoundError, ForbiddenError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { messagesDal } from './messages.dal'

export const messagesService = {
  async getConversations(userId: string, role: string) {
    return messagesDal.getConversations(userId, role)
  },

  async getMessages(userId: string, bookingId: string, page: number, limit: number) {
    const booking = await messagesDal.findBookingById(bookingId)
    if (!booking) throw new NotFoundError('Booking')
    if (booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new ForbiddenError()
    }

    const skip = (page - 1) * limit
    const [messages, total] = await Promise.all([
      messagesDal.getMessages(bookingId, skip, limit),
      messagesDal.countMessages(bookingId),
    ])

    // Mark as read
    await messagesDal.markAsRead(bookingId, userId)

    return { messages, pagination: { total, page, limit } }
  },

  async sendMessage(userId: string, bookingId: string, text: string) {
    const booking = await messagesDal.findBookingById(bookingId)
    if (!booking) throw new NotFoundError('Booking')
    if (booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new ForbiddenError()
    }

    const msg = await messagesDal.createMessage(bookingId, userId, text)
    logger.info('Message sent', { bookingId, userId, messageId: msg.id })
    return msg
  },
}
