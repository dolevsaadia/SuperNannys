import type { BookingStatus } from '@prisma/client'
import { AppError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { parsePagination, paginationMeta } from '../../shared/utils/pagination'
import { bookingsDal } from './bookings.dal'
import type { CreateBookingInput } from './bookings.validation'

export const bookingsService = {
  async create(parentUserId: string, data: CreateBookingInput) {
    logger.info('booking:create:start', {
      module: 'bookings',
      parentUserId,
      nannyUserId: data.nannyUserId,
      startTime: data.startTime,
      endTime: data.endTime,
    })

    if (parentUserId === data.nannyUserId) {
      throw new AppError('Cannot book yourself', 400)
    }

    const start = new Date(data.startTime)
    const end = new Date(data.endTime)
    if (end <= start) throw new AppError('End time must be after start time')

    const nannyProfile = await bookingsDal.findNannyProfile(data.nannyUserId)
    if (!nannyProfile) throw new AppError('Nanny not found', 404)

    // ── Conflict detection: existing bookings ─────────────
    const conflict = await bookingsDal.findConflict(data.nannyUserId, start, end)
    if (conflict) throw new AppError('Nanny is not available for this time slot', 409)

    // ── Conflict detection: date-specific blocked slots ───
    const dateBlock = await bookingsDal.findDateBlock(
      nannyProfile.id,
      start, // date
      `${String(start.getHours()).padStart(2, '0')}:${String(start.getMinutes()).padStart(2, '0')}`,
      `${String(end.getHours()).padStart(2, '0')}:${String(end.getMinutes()).padStart(2, '0')}`,
    )
    if (dateBlock) throw new AppError('Nanny has blocked this date/time in her calendar', 409)

    const durationHours = (end.getTime() - start.getTime()) / 3_600_000

    // Use recurring rate if this booking is explicitly marked as recurring, otherwise casual
    const isRecurring = !!data.isRecurring
    const rate = isRecurring && nannyProfile.recurringHourlyRateNis
      ? nannyProfile.recurringHourlyRateNis
      : nannyProfile.hourlyRateNis

    if (!rate || rate <= 0) {
      throw new AppError('Nanny has no rate configured', 400)
    }

    // Estimated price based on booked hours (actual price determined by timer)
    const estimatedPriceNis = Math.round(durationHours * rate)
    if (!isFinite(estimatedPriceNis) || estimatedPriceNis < 0) {
      throw new AppError('Invalid price calculation — check rate and duration', 400)
    }

    // If nanny has minimum hours, ensure estimate reflects at least the minimum
    const minHours = nannyProfile.minimumHoursPerBooking || 0
    const chargeableHours = Math.max(durationHours, minHours)
    const totalAmountNis = Math.round(chargeableHours * rate)
    if (!isFinite(totalAmountNis) || totalAmountNis < 0) {
      throw new AppError('Invalid total price calculation', 400)
    }

    // Build structured address data (only include defined fields)
    const addressData: Record<string, unknown> = {}
    if (data.address) addressData.address = data.address
    if (data.bookingCity) addressData.bookingCity = data.bookingCity
    if (data.bookingStreet) addressData.bookingStreet = data.bookingStreet
    if (data.bookingHouseNum) addressData.bookingHouseNum = data.bookingHouseNum
    if (data.bookingPostalCode) addressData.bookingPostalCode = data.bookingPostalCode
    if (data.bookingLat) addressData.bookingLat = data.bookingLat
    if (data.bookingLng) addressData.bookingLng = data.bookingLng
    if (data.locationType) addressData.locationType = data.locationType

    const booking = await bookingsDal.create({
      parentUserId,
      nannyUserId: data.nannyUserId,
      startTime: start,
      endTime: end,
      hourlyRateNis: rate,
      totalAmountNis,
      estimatedPriceNis,
      notes: data.notes,
      childrenCount: data.childrenCount,
      childrenAges: data.childrenAges,
      isRecurring,
      ...addressData,
    })

    logger.info('Booking created', {
      bookingId: booking.id,
      parentUserId,
      nannyUserId: data.nannyUserId,
      startTime: start.toISOString(),
      totalAmountNis,
    })

    return booking
  },

  async list(userId: string, role: string, filters: { status?: string; page?: string; limit?: string }) {
    const where: Record<string, unknown> =
      role === 'PARENT' ? { parentUserId: userId } :
      role === 'NANNY' ? { nannyUserId: userId } : {}

    if (filters.status) where.status = filters.status

    const { page, limit, skip } = parsePagination(filters)

    const [bookings, total] = await Promise.all([
      bookingsDal.findMany(where, skip, limit),
      bookingsDal.count(where),
    ])

    return { bookings, pagination: paginationMeta(total, page, limit) }
  },

  async getById(userId: string, role: string, bookingId: string) {
    const booking = await bookingsDal.findById(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)

    if (booking.parentUserId !== userId && booking.nannyUserId !== userId && role !== 'ADMIN') {
      throw new AppError('Forbidden', 403)
    }
    return booking
  },

  async updateStatus(userId: string, role: string, bookingId: string, status: BookingStatus) {
    const booking = await bookingsDal.findByIdSimple(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)

    // Guard: IN_PROGRESS and COMPLETED transitions go through sessions module only
    if (status === 'IN_PROGRESS') {
      throw new AppError('Use the sessions API to start a live session', 400)
    }
    if (status === 'COMPLETED') {
      throw new AppError('Use the sessions API to end a live session', 400)
    }

    // Authorization checks
    if ((status === 'ACCEPTED' || status === 'DECLINED') && booking.nannyUserId !== userId) {
      throw new AppError('Only the nanny can accept/decline', 403)
    }
    if (status === 'CANCELLED' && booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new AppError('Forbidden', 403)
    }

    const updated = await bookingsDal.updateStatus(bookingId, status)

    logger.info('Booking status updated', { bookingId, status, userId })

    return updated
  },
}
