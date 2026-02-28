import { AppError } from '../../shared/errors/app-error'
import { reviewsDal } from './reviews.dal'
import type { CreateReviewInput } from './reviews.validation'

export const reviewsService = {
  async create(reviewerUserId: string, data: CreateReviewInput) {
    const booking = await reviewsDal.findBookingById(data.bookingId)
    if (!booking) throw new AppError('Booking not found', 404)
    if (booking.parentUserId !== reviewerUserId) throw new AppError('Forbidden', 403)
    if (booking.status !== 'COMPLETED') throw new AppError('Can only review completed bookings')

    const existing = await reviewsDal.findExistingReview(data.bookingId)
    if (existing) throw new AppError('Review already submitted', 409)

    const review = await reviewsDal.createReview({
      bookingId: data.bookingId,
      reviewerUserId,
      revieweeUserId: booking.nannyUserId,
      rating: data.rating,
      comment: data.comment,
    })

    // Recalculate aggregate rating
    const stats = await reviewsDal.aggregateRatings(booking.nannyUserId)
    await reviewsDal.updateNannyRating(
      booking.nannyUserId,
      Math.round((stats._avg.rating || 0) * 10) / 10,
      stats._count,
    )

    return review
  },

  async getByNanny(nannyUserId: string, page: number, limit: number) {
    const skip = (page - 1) * limit
    const [reviews, total] = await Promise.all([
      reviewsDal.getByNanny(nannyUserId, skip, limit),
      reviewsDal.countByNanny(nannyUserId),
    ])
    return { reviews, pagination: { total, page, limit } }
  },
}
