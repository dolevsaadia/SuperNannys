import type { RecurringBookingStatus } from '@prisma/client'
import { AppError } from '../../shared/errors/app-error'
import { recurringBookingsDal } from './recurring-bookings.dal'
import { bookingsDal } from '../bookings/bookings.dal'
import type { CreateRecurringBookingInput, UpdateRecurringBookingInput } from './recurring-bookings.validation'
import { logger } from '../../shared/utils/logger'
import { parsePagination, paginationMeta } from '../../shared/utils/pagination'

/**
 * Parse a "HH:mm" time string into [hours, minutes].
 * Returns [0, 0] and logs an error if the format is invalid.
 */
function parseTime(timeStr: string): [number, number] {
  const parts = timeStr.split(':')
  const h = Number(parts[0])
  const m = Number(parts[1])
  if (isNaN(h) || isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59) {
    logger.error('Invalid time format', { timeStr, parsedH: h, parsedM: m })
    return [0, 0]
  }
  return [h, m]
}

export const recurringBookingsService = {
  async create(parentUserId: string, data: CreateRecurringBookingInput) {
    if (parentUserId === data.nannyUserId) {
      throw new AppError('Cannot create a recurring booking with yourself', 400)
    }

    const nannyProfile = await recurringBookingsDal.findNannyProfile(data.nannyUserId)
    if (!nannyProfile) throw new AppError('Nanny not found', 404)

    const rate = nannyProfile.recurringHourlyRateNis ?? nannyProfile.hourlyRateNis
    if (!rate || rate <= 0) {
      throw new AppError('Nanny has no rate configured', 400)
    }

    const startDate = new Date(data.startDate)
    const endDate = data.endDate ? new Date(data.endDate) : null

    if (endDate && endDate <= startDate) {
      throw new AppError('End date must be after start date', 400)
    }

    const recurring = await recurringBookingsDal.create({
      parentUserId,
      nannyUserId: data.nannyUserId,
      daysOfWeek: data.daysOfWeek,
      startTime: data.startTime,
      endTime: data.endTime,
      startDate,
      endDate,
      hourlyRateNis: rate,
      childrenCount: data.childrenCount,
      childrenAges: data.childrenAges,
      address: data.address,
      notes: data.notes,
    })

    logger.info('Recurring booking created', {
      id: recurring.id,
      parentUserId,
      nannyUserId: data.nannyUserId,
    })

    return recurring
  },

  async list(userId: string, role: string, filters: { status?: string; page?: string; limit?: string }) {
    const where: Record<string, unknown> =
      role === 'PARENT' ? { parentUserId: userId } :
      role === 'NANNY' ? { nannyUserId: userId } : {}

    if (filters.status) where.status = filters.status

    const { page, limit, skip } = parsePagination(filters)

    const [items, total] = await Promise.all([
      recurringBookingsDal.findMany(where, skip, limit),
      recurringBookingsDal.count(where),
    ])

    return { recurringBookings: items, pagination: paginationMeta(total, page, limit) }
  },

  async getById(userId: string, role: string, id: string) {
    const rb = await recurringBookingsDal.findById(id)
    if (!rb) throw new AppError('Recurring booking not found', 404)

    if (rb.parentUserId !== userId && rb.nannyUserId !== userId && role !== 'ADMIN') {
      throw new AppError('Forbidden', 403)
    }

    return rb
  },

  async update(userId: string, role: string, id: string, data: UpdateRecurringBookingInput) {
    const rb = await recurringBookingsDal.findById(id)
    if (!rb) throw new AppError('Recurring booking not found', 404)

    // Only the parent who created it or admin can update
    if (rb.parentUserId !== userId && role !== 'ADMIN') {
      throw new AppError('Only the parent can update this recurring booking', 403)
    }

    // Can only update if PENDING, ACTIVE or PAUSED
    if (!['PENDING', 'ACTIVE', 'PAUSED'].includes(rb.status)) {
      throw new AppError(`Cannot update a ${rb.status.toLowerCase()} recurring booking`, 400)
    }

    const updateData: Record<string, unknown> = { ...data }
    if (data.endDate !== undefined) {
      updateData.endDate = data.endDate ? new Date(data.endDate) : null
    }

    return recurringBookingsDal.update(id, updateData)
  },

  async updateStatus(userId: string, role: string, id: string, status: RecurringBookingStatus) {
    const rb = await recurringBookingsDal.findById(id)
    if (!rb) throw new AppError('Recurring booking not found', 404)

    // Authorization
    if (rb.parentUserId !== userId && rb.nannyUserId !== userId && role !== 'ADMIN') {
      throw new AppError('Forbidden', 403)
    }

    // Nanny can only ACTIVE (accept) or CANCELLED (decline) from PENDING
    if (rb.nannyUserId === userId && rb.parentUserId !== userId) {
      if (status === 'ACTIVE' && rb.status !== 'PENDING') {
        throw new AppError('Can only accept a pending recurring booking', 400)
      }
      if (status === 'CANCELLED' && !['PENDING', 'ACTIVE', 'PAUSED'].includes(rb.status)) {
        throw new AppError('Cannot cancel at this stage', 400)
      }
    }

    // Parent can PAUSE, CANCELLED, ENDED
    if (rb.parentUserId === userId) {
      if (status === 'ACTIVE' && rb.status === 'PAUSED') {
        // Resume — allowed
      } else if (status === 'ACTIVE') {
        throw new AppError('Only nanny can accept a pending recurring booking', 400)
      }
    }

    const updated = await recurringBookingsDal.updateStatus(id, status)

    logger.info('Recurring booking status updated', { id, status, userId })

    // If activating, generate initial 2-week batch of bookings
    if (status === 'ACTIVE' && rb.status === 'PENDING') {
      await this.generateOccurrences(updated.id, 14)
    }

    return updated
  },

  /**
   * Generate booking occurrences for a recurring booking,
   * for the next `daysAhead` days starting from today or last generated date.
   */
  async generateOccurrences(recurringBookingId: string, daysAhead: number = 7) {
    const rb = await recurringBookingsDal.findById(recurringBookingId)
    if (!rb || rb.status !== 'ACTIVE') return 0

    const rate = rb.hourlyRateNis

    // Parse start/end times with validation
    const [startH, startM] = parseTime(rb.startTime)
    const [endH, endM] = parseTime(rb.endTime)
    const durationHours = (endH + endM / 60) - (startH + startM / 60)

    const totalAmountNis = Math.round(durationHours * rate)

    // Calculate date range
    const fromDate = rb.lastGeneratedAt
      ? new Date(new Date(rb.lastGeneratedAt).getTime() + 86400000) // day after last generated
      : new Date(Math.max(rb.startDate.getTime(), Date.now()))

    const toDate = new Date(Date.now() + daysAhead * 86400000)

    // Respect endDate
    const effectiveEnd = rb.endDate && rb.endDate < toDate ? rb.endDate : toDate

    let count = 0
    const cursor = new Date(fromDate)
    cursor.setHours(0, 0, 0, 0)

    while (cursor <= effectiveEnd) {
      if (count >= 100) {
        logger.warn('Max occurrences per run (100) reached, stopping generation', {
          recurringBookingId,
        })
        break
      }

      const dayOfWeek = cursor.getDay()

      if (rb.daysOfWeek.includes(dayOfWeek)) {
        const occurrenceDate = new Date(cursor)

        // Check if occurrence already exists
        const existing = await recurringBookingsDal.findExistingOccurrence(recurringBookingId, occurrenceDate)
        if (!existing) {
          const startTime = new Date(cursor)
          startTime.setHours(startH, startM, 0, 0)

          const endTime = new Date(cursor)
          endTime.setHours(endH, endM, 0, 0)

          await bookingsDal.create({
            parentUserId: rb.parentUserId,
            nannyUserId: rb.nannyUserId,
            startTime,
            endTime,
            hourlyRateNis: rate,
            totalAmountNis,
            notes: rb.notes || undefined,
            childrenCount: rb.childrenCount,
            childrenAges: rb.childrenAges,
            address: rb.address || undefined,
            isRecurring: true,
            recurringBookingId: rb.id,
            occurrenceDate,
            status: 'ACCEPTED', // Nanny already approved the recurring arrangement
          })
          count++
          logger.debug('Occurrence created', {
            recurringBookingId,
            occurrenceDate: occurrenceDate.toISOString(),
            count,
          })
        }
      }

      cursor.setDate(cursor.getDate() + 1)
    }

    // Update lastGeneratedAt
    await recurringBookingsDal.updateLastGenerated(recurringBookingId, effectiveEnd)
    logger.info(`Generated ${count} occurrences for recurring booking ${recurringBookingId}`)
    return count
  },
}
