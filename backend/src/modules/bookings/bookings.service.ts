import type { BookingStatus } from '@prisma/client'
import { config } from '../../config'
import { AppError } from '../../shared/errors/app-error'
import { bookingsDal } from './bookings.dal'
import type { CreateBookingInput } from './bookings.validation'

export const bookingsService = {
  async create(parentUserId: string, data: CreateBookingInput) {
    const start = new Date(data.startTime)
    const end = new Date(data.endTime)
    if (end <= start) throw new AppError('End time must be after start time')

    const nannyProfile = await bookingsDal.findNannyProfile(data.nannyUserId)
    if (!nannyProfile) throw new AppError('Nanny not found', 404)

    const conflict = await bookingsDal.findConflict(data.nannyUserId, start, end)
    if (conflict) throw new AppError('Nanny is not available for this time slot', 409)

    const durationHours = (end.getTime() - start.getTime()) / 3_600_000
    const totalAmountNis = Math.round(durationHours * nannyProfile.hourlyRateNis)

    return bookingsDal.create({
      parentUserId,
      nannyUserId: data.nannyUserId,
      startTime: start,
      endTime: end,
      hourlyRateNis: nannyProfile.hourlyRateNis,
      totalAmountNis,
      notes: data.notes,
      childrenCount: data.childrenCount,
      childrenAges: data.childrenAges,
      address: data.address,
    })
  },

  async list(userId: string, role: string, filters: { status?: string; page?: string; limit?: string }) {
    const where: Record<string, unknown> =
      role === 'PARENT' ? { parentUserId: userId } :
      role === 'NANNY' ? { nannyUserId: userId } : {}

    if (filters.status) where.status = filters.status

    const pageNum = Math.max(1, parseInt(filters.page || '1'))
    const limitNum = Math.min(50, parseInt(filters.limit || '20'))
    const skip = (pageNum - 1) * limitNum

    const [bookings, total] = await Promise.all([
      bookingsDal.findMany(where, skip, limitNum),
      bookingsDal.count(where),
    ])

    return { bookings, pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) } }
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

    // Authorization checks
    if ((status === 'ACCEPTED' || status === 'DECLINED') && booking.nannyUserId !== userId) {
      throw new AppError('Only the nanny can accept/decline', 403)
    }
    if (status === 'CANCELLED' && booking.parentUserId !== userId && booking.nannyUserId !== userId) {
      throw new AppError('Forbidden', 403)
    }
    if (status === 'COMPLETED' && booking.nannyUserId !== userId) {
      throw new AppError('Only the nanny can mark completed', 403)
    }

    const updated = await bookingsDal.updateStatus(bookingId, status)

    // Create earnings on completion
    if (status === 'COMPLETED') {
      const platformFee = Math.round(updated.totalAmountNis * config.platformFeePercent / 100)
      const netAmount = updated.totalAmountNis - platformFee
      await bookingsDal.upsertEarning({
        nannyUserId: updated.nannyUserId,
        bookingId: updated.id,
        amountNis: updated.totalAmountNis,
        platformFee,
        netAmountNis: netAmount,
      })
      await bookingsDal.updateNannyStats(updated.nannyUserId, netAmount)
    }

    return updated
  },
}
