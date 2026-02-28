import { AppError } from '../../shared/errors/app-error'
import { messagesDal } from './messages.dal'

export const messagesService = {
  async getConversations(userId: string, role: string) {
    return messagesDal.getConversations(userId, role)
  },

  async getMessages(userId: string, bookingId: string, page: number, limit: number) {
    const booking = await messagesDal.findBookingById(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)
    if (booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new AppError('Forbidden', 403)
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
    if (!booking) throw new AppError('Booking not found', 404)
    if (booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new AppError('Forbidden', 403)
    }

    return messagesDal.createMessage(bookingId, userId, text)
  },
}
