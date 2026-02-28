import { prisma } from '../../db'

export const reviewsDal = {
  findBookingById(bookingId: string) {
    return prisma.booking.findUnique({ where: { id: bookingId } })
  },

  findExistingReview(bookingId: string) {
    return prisma.review.findUnique({ where: { bookingId } })
  },

  createReview(data: { bookingId: string; reviewerUserId: string; revieweeUserId: string; rating: number; comment?: string }) {
    return prisma.review.create({ data })
  },

  aggregateRatings(revieweeUserId: string) {
    return prisma.review.aggregate({
      where: { revieweeUserId },
      _avg: { rating: true },
      _count: true,
    })
  },

  updateNannyRating(nannyUserId: string, rating: number, count: number) {
    return prisma.nannyProfile.update({
      where: { userId: nannyUserId },
      data: { rating, reviewsCount: count },
    })
  },

  getByNanny(nannyUserId: string, skip: number, take: number) {
    return prisma.review.findMany({
      where: { revieweeUserId: nannyUserId },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      include: { reviewer: { select: { fullName: true, avatarUrl: true } } },
    })
  },

  countByNanny(nannyUserId: string) {
    return prisma.review.count({ where: { revieweeUserId: nannyUserId } })
  },
}
