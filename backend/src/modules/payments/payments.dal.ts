import { prisma } from '../../db'

export const paymentsDal = {
  findBookingById(bookingId: string) {
    return prisma.booking.findUnique({ where: { id: bookingId } })
  },

  updateBookingPaymentIntent(bookingId: string, paymentIntentId: string) {
    return prisma.booking.update({ where: { id: bookingId }, data: { paymentIntentId } })
  },

  markBookingPaid(paymentIntentId: string) {
    return prisma.booking.updateMany({
      where: { paymentIntentId },
      data: { isPaid: true },
    })
  },

  getPaymentMethods(userId: string) {
    return prisma.paymentMethod.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    })
  },

  clearDefaultPaymentMethods(userId: string) {
    return prisma.paymentMethod.updateMany({
      where: { userId },
      data: { isDefault: false },
    })
  },

  createPaymentMethod(userId: string, data: Record<string, unknown>) {
    return prisma.paymentMethod.create({
      data: { userId, ...data } as any,
    })
  },
}
