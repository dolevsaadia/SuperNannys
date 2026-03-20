import type { BookingStatus } from '@prisma/client'
import { AppError, NotFoundError, ConflictError, ForbiddenError, BadRequestError, ValidationError } from '../../shared/errors/app-error'
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
      throw new BadRequestError('Cannot book yourself')
    }

    const start = new Date(data.startTime)
    const end = new Date(data.endTime)
    if (end <= start) throw new ValidationError('End time must be after start time')

    const nannyProfile = await bookingsDal.findNannyProfile(data.nannyUserId)
    if (!nannyProfile) throw new NotFoundError('Nanny')

    // ── Block bookings for unverified/inactive nannies ─────
    if (!nannyProfile.user?.isVerified) throw new ForbiddenError('This nanny has not been verified yet')
    if (!nannyProfile.user?.isActive) throw new ForbiddenError('This nanny account is not active')

    // ── Conflict detection: existing bookings ─────────────
    const conflict = await bookingsDal.findConflict(data.nannyUserId, start, end)
    if (conflict) throw new ConflictError('Nanny is not available for this time slot')

    // ── Conflict detection: date-specific blocked slots ───
    const dateBlock = await bookingsDal.findDateBlock(
      nannyProfile.id,
      start, // date
      `${String(start.getHours()).padStart(2, '0')}:${String(start.getMinutes()).padStart(2, '0')}`,
      `${String(end.getHours()).padStart(2, '0')}:${String(end.getMinutes()).padStart(2, '0')}`,
    )
    if (dateBlock) throw new ConflictError('Nanny has blocked this date/time in her calendar')

    const durationHours = (end.getTime() - start.getTime()) / 3_600_000

    // Use recurring rate if this booking is explicitly marked as recurring, otherwise casual
    const isRecurring = !!data.isRecurring
    const rate = isRecurring && nannyProfile.recurringHourlyRateNis
      ? nannyProfile.recurringHourlyRateNis
      : nannyProfile.hourlyRateNis

    if (!rate || rate <= 0) {
      throw new ValidationError('Nanny has no rate configured')
    }

    // Estimated price based on booked hours (actual price determined by timer)
    const estimatedPriceNis = Math.round(durationHours * rate)
    if (!isFinite(estimatedPriceNis) || estimatedPriceNis < 0) {
      throw new ValidationError('Invalid price calculation — check rate and duration')
    }

    // If nanny has minimum hours, ensure estimate reflects at least the minimum
    const minHours = nannyProfile.minimumHoursPerBooking || 0
    const chargeableHours = Math.max(durationHours, minHours)
    const totalAmountNis = Math.round(chargeableHours * rate)
    if (!isFinite(totalAmountNis) || totalAmountNis < 0) {
      throw new ValidationError('Invalid total price calculation')
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
    if (!booking) throw new NotFoundError('Booking', bookingId)

    if (booking.parentUserId !== userId && booking.nannyUserId !== userId && role !== 'ADMIN') {
      throw new ForbiddenError()
    }
    return booking
  },

  async updateStatus(userId: string, role: string, bookingId: string, status: BookingStatus) {
    const booking = await bookingsDal.findByIdSimple(bookingId)
    if (!booking) throw new NotFoundError('Booking', bookingId)

    // Guard: IN_PROGRESS and COMPLETED transitions go through sessions module only
    if (status === 'IN_PROGRESS') {
      throw new BadRequestError('Use the sessions API to start a live session')
    }
    if (status === 'COMPLETED') {
      throw new BadRequestError('Use the sessions API to end a live session')
    }

    // ── Valid state transition map ────────────────────────
    const validTransitions: Record<string, string[]> = {
      REQUESTED: ['ACCEPTED', 'DECLINED', 'CANCELLED'],
      ACCEPTED:  ['CANCELLED'],
      DECLINED:  [],          // terminal
      CANCELLED: [],          // terminal
      IN_PROGRESS: [],        // managed by sessions API
      COMPLETED: [],          // terminal
    }
    const allowed = validTransitions[booking.status] || []
    if (!allowed.includes(status)) {
      throw new BadRequestError(`Cannot transition from ${booking.status} to ${status}`)
    }

    // Authorization checks
    if ((status === 'ACCEPTED' || status === 'DECLINED') && booking.nannyUserId !== userId) {
      throw new ForbiddenError('Only the nanny can accept/decline')
    }
    if (status === 'CANCELLED' && booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new ForbiddenError()
    }

    const updated = await bookingsDal.updateStatus(bookingId, status)

    logger.info('Booking status updated', { bookingId, status, userId })

    return updated
  },
}
