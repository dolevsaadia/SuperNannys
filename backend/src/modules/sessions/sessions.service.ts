import { Server as SocketIOServer } from 'socket.io'
import { config } from '../../config'
import { AppError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { sessionsDal } from './sessions.dal'
import { sessionTimer } from './session-timer'
import { paymentsService } from '../payments/payments.service'

let ioRef: SocketIOServer | null = null

export const sessionsService = {
  setIO(io: SocketIOServer) {
    ioRef = io
    sessionTimer.setIO(io)
  },

  // ── Confirm Start ──────────────────────────────────────────
  async confirmStart(userId: string, role: string, bookingId: string) {
    const booking = await sessionsDal.findBookingByIdSimple(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)

    // Only ACCEPTED bookings can start a session
    if (booking.status !== 'ACCEPTED') {
      throw new AppError('Booking must be accepted before starting a session', 400)
    }

    // Check user is part of this booking
    const isParent = booking.parentUserId === userId
    const isNanny = booking.nannyUserId === userId
    if (!isParent && !isNanny && role !== 'ADMIN') {
      throw new AppError('Forbidden', 403)
    }

    // Time window check: 30 min before to 60 min after scheduled start
    // (widened to accommodate clock skew and user delays)
    const now = new Date()
    const scheduled = new Date(booking.startTime)
    const windowStart = new Date(scheduled.getTime() - 30 * 60_000)
    const windowEnd = new Date(scheduled.getTime() + 60 * 60_000)

    if (now < windowStart || now > windowEnd) {
      throw new AppError(
        `Session can only be started between ${windowStart.toISOString()} and ${windowEnd.toISOString()} (scheduled: ${scheduled.toISOString()}, now: ${now.toISOString()})`,
        400,
      )
    }

    // Prevent double confirmation
    if (isParent && booking.parentConfirmedStart) {
      throw new AppError('You have already confirmed start', 400)
    }
    if (isNanny && booking.nannyConfirmedStart) {
      throw new AppError('You have already confirmed start', 400)
    }

    // Mark confirmation
    let updated
    if (isParent) {
      updated = await sessionsDal.confirmParentStart(bookingId)
    } else {
      updated = await sessionsDal.confirmNannyStart(bookingId)
    }

    // If this is the first confirmation, start the auto-cancel timeout
    const isFirstConfirmation =
      (isParent && !booking.nannyConfirmedStart) ||
      (isNanny && !booking.parentConfirmedStart)
    if (isFirstConfirmation) {
      this.scheduleStartTimeout(bookingId)
    }

    // Emit who confirmed
    if (ioRef) {
      ioRef.to(`booking:${bookingId}`).emit('session:start-confirmed', {
        bookingId,
        confirmedBy: isParent ? 'parent' : 'nanny',
        parentConfirmed: updated.parentConfirmedStart,
        nannyConfirmed: updated.nannyConfirmedStart,
      })
    }

    // Check if both confirmed
    if (updated.parentConfirmedStart && updated.nannyConfirmedStart) {
      const actualStartTime = new Date()
      const started = await sessionsDal.startSession(bookingId, actualStartTime)

      // Calculate booked duration in minutes
      const bookedDurationMin = Math.round(
        (new Date(booking.endTime).getTime() - new Date(booking.startTime).getTime()) / 60_000,
      )

      // Start the timer
      sessionTimer.start(bookingId, actualStartTime, bookedDurationMin, booking.hourlyRateNis)

      // Emit session started
      if (ioRef) {
        ioRef.to(`booking:${bookingId}`).emit('session:started', {
          bookingId,
          actualStartTime: actualStartTime.toISOString(),
          bookedDurationMin,
          hourlyRateNis: booking.hourlyRateNis,
        })
      }

      return { phase: 'active', booking: started }
    }

    return { phase: 'waiting_confirmation', booking: updated }
  },

  // ── Request End ──────────────────────────────────────────
  async requestEnd(userId: string, role: string, bookingId: string) {
    const booking = await sessionsDal.findBookingByIdSimple(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)

    if (booking.status !== 'IN_PROGRESS') {
      throw new AppError('Session is not active', 400)
    }

    const isParent = booking.parentUserId === userId
    const isNanny = booking.nannyUserId === userId
    if (!isParent && !isNanny && role !== 'ADMIN') {
      throw new AppError('Forbidden', 403)
    }

    // Mark this user's end confirmation
    let updated
    if (isParent) {
      if (booking.parentConfirmedEnd) throw new AppError('You have already requested end', 400)
      updated = await sessionsDal.confirmParentEnd(bookingId)
    } else {
      if (booking.nannyConfirmedEnd) throw new AppError('You have already requested end', 400)
      updated = await sessionsDal.confirmNannyEnd(bookingId)
    }

    // Emit end request
    if (ioRef) {
      ioRef.to(`booking:${bookingId}`).emit('session:end-requested', {
        bookingId,
        requestedBy: isParent ? 'parent' : 'nanny',
        parentConfirmed: updated.parentConfirmedEnd,
        nannyConfirmed: updated.nannyConfirmedEnd,
      })
    }

    // Check if both confirmed end
    if (updated.parentConfirmedEnd && updated.nannyConfirmedEnd) {
      return this.finalizeSession(bookingId)
    }

    // First person to request end → schedule auto-finalize timeout (10 min)
    this.scheduleEndTimeout(bookingId)

    return { phase: 'waiting_end_confirmation', booking: updated }
  },

  // ── Confirm End (second party confirms) ───────────────────
  async confirmEnd(userId: string, role: string, bookingId: string) {
    // Same logic as requestEnd — the second caller triggers finalization
    return this.requestEnd(userId, role, bookingId)
  },

  // ── Finalize Session ──────────────────────────────────────
  async finalizeSession(bookingId: string) {
    const calcResult = sessionTimer.calculateFinal(bookingId)

    let actualDurationMin: number
    let finalAmountNis: number
    let overtimeAmountNis: number

    if (calcResult) {
      actualDurationMin = calcResult.actualDurationMin
      finalAmountNis = calcResult.finalAmountNis
      overtimeAmountNis = calcResult.overtimeAmountNis
    } else {
      // Fallback: calculate from DB if timer not found (server restart edge case)
      const booking = await sessionsDal.findBookingByIdSimple(bookingId)
      if (!booking || !booking.actualStartTime) {
        throw new AppError('Cannot finalize session — no start time found', 500)
      }
      const now = new Date()
      const elapsedMs = now.getTime() - new Date(booking.actualStartTime).getTime()
      actualDurationMin = Math.round(elapsedMs / 60_000)

      const bookedDurationMin = Math.round(
        (new Date(booking.endTime).getTime() - new Date(booking.startTime).getTime()) / 60_000,
      )
      const baseAmount = booking.totalAmountNis

      if (actualDurationMin <= bookedDurationMin) {
        finalAmountNis = baseAmount
        overtimeAmountNis = 0
      } else {
        const overtimeMin = actualDurationMin - bookedDurationMin
        const overtimeBlocks = Math.ceil(overtimeMin / 15)
        overtimeAmountNis = Math.round((overtimeBlocks * 15 / 60) * booking.hourlyRateNis)
        finalAmountNis = baseAmount + overtimeAmountNis
      }
    }

    // Stop the timer
    sessionTimer.stop(bookingId)

    // Update booking
    const completed = await sessionsDal.completeSession(bookingId, {
      actualEndTime: new Date(),
      actualDurationMin,
      finalAmountNis,
      overtimeAmountNis,
    })

    // Create earning record
    const platformFee = Math.round(finalAmountNis * config.platformFeePercent / 100)
    const netAmountNis = finalAmountNis - platformFee

    await sessionsDal.upsertEarning({
      nannyUserId: completed.nannyUserId,
      bookingId: completed.id,
      amountNis: finalAmountNis,
      platformFee,
      netAmountNis,
    })

    await sessionsDal.updateNannyStats(completed.nannyUserId, netAmountNis)

    // Emit session ended
    if (ioRef) {
      ioRef.to(`booking:${bookingId}`).emit('session:ended', {
        bookingId,
        actualDurationMin,
        finalAmountNis,
        overtimeAmountNis,
        platformFee,
        netAmountNis,
      })
    }

    logger.info(`Session completed: ${bookingId} | ${actualDurationMin}min | ₪${finalAmountNis}`)

    // Charge the parent asynchronously (don't block response)
    paymentsService.chargeAfterSession(bookingId, finalAmountNis).catch(err => {
      logger.error(`Failed to charge after session: ${bookingId}`, { err })
    })

    return {
      phase: 'ended',
      booking: completed,
      summary: {
        actualDurationMin,
        finalAmountNis,
        overtimeAmountNis,
        platformFee,
        netAmountNis,
      },
    }
  },

  // ── Get Session State ─────────────────────────────────────
  async getState(userId: string, role: string, bookingId: string) {
    const booking = await sessionsDal.findBookingById(bookingId)
    if (!booking) throw new AppError('Booking not found', 404)

    const isParent = booking.parentUserId === userId
    const isNanny = booking.nannyUserId === userId
    if (!isParent && !isNanny && role !== 'ADMIN') {
      throw new AppError('Forbidden', 403)
    }

    const timerState = sessionTimer.getState(bookingId)
    const bookedDurationMin = Math.round(
      (new Date(booking.endTime).getTime() - new Date(booking.startTime).getTime()) / 60_000,
    )

    // Determine phase
    let phase: string
    if (booking.status === 'COMPLETED') {
      phase = 'ended'
    } else if (booking.status === 'IN_PROGRESS') {
      if (booking.parentConfirmedEnd || booking.nannyConfirmedEnd) {
        phase = 'waiting_end_confirmation'
      } else {
        phase = 'active'
      }
    } else if (booking.status === 'ACCEPTED') {
      if (booking.parentConfirmedStart || booking.nannyConfirmedStart) {
        phase = 'waiting_start_confirmation'
      } else {
        phase = 'prompt_start'
      }
    } else {
      phase = 'idle'
    }

    return {
      phase,
      bookingId: booking.id,
      status: booking.status,
      parentConfirmedStart: booking.parentConfirmedStart,
      nannyConfirmedStart: booking.nannyConfirmedStart,
      parentConfirmedEnd: booking.parentConfirmedEnd,
      nannyConfirmedEnd: booking.nannyConfirmedEnd,
      actualStartTime: booking.actualStartTime?.toISOString() ?? null,
      actualEndTime: booking.actualEndTime?.toISOString() ?? null,
      actualDurationMin: booking.actualDurationMin,
      finalAmountNis: booking.finalAmountNis,
      overtimeAmountNis: booking.overtimeAmountNis,
      bookedDurationMin,
      hourlyRateNis: booking.hourlyRateNis,
      totalAmountNis: booking.totalAmountNis,
      timer: timerState,
      booking,
    }
  },

  // ── Get Active Session ────────────────────────────────────
  async getActive(userId: string) {
    const booking = await sessionsDal.findActiveSession(userId)
    if (!booking) return null

    const timerState = sessionTimer.getState(booking.id)
    const bookedDurationMin = Math.round(
      (new Date(booking.endTime).getTime() - new Date(booking.startTime).getTime()) / 60_000,
    )

    return {
      phase: 'active',
      bookingId: booking.id,
      status: booking.status,
      parentConfirmedStart: booking.parentConfirmedStart,
      nannyConfirmedStart: booking.nannyConfirmedStart,
      parentConfirmedEnd: booking.parentConfirmedEnd,
      nannyConfirmedEnd: booking.nannyConfirmedEnd,
      actualStartTime: booking.actualStartTime?.toISOString() ?? null,
      bookedDurationMin,
      hourlyRateNis: booking.hourlyRateNis,
      totalAmountNis: booking.totalAmountNis,
      timer: timerState,
      booking,
    }
  },

  // ── Auto-timeout for unconfirmed start (15 min) ──────────
  scheduleStartTimeout(bookingId: string) {
    setTimeout(async () => {
      try {
        const booking = await sessionsDal.findBookingByIdSimple(bookingId)
        if (!booking) return
        // If still ACCEPTED and not both confirmed → cancel
        if (booking.status === 'ACCEPTED' && !(booking.parentConfirmedStart && booking.nannyConfirmedStart)) {
          await sessionsDal.cancelBooking(bookingId)
          if (ioRef) {
            ioRef.to(`booking:${bookingId}`).emit('session:timeout', {
              bookingId,
              reason: 'start_not_confirmed',
            })
          }
          logger.info(`Session start timeout — booking cancelled: ${bookingId}`)
        }
      } catch (err) {
        logger.error('Start timeout error', { bookingId, err })
      }
    }, 15 * 60_000) // 15 minutes
  },

  // ── Auto-timeout for unconfirmed end (10 min) ────────────
  scheduleEndTimeout(bookingId: string) {
    setTimeout(async () => {
      try {
        const booking = await sessionsDal.findBookingByIdSimple(bookingId)
        if (!booking) return
        // If still IN_PROGRESS and one side confirmed end but not both
        if (
          booking.status === 'IN_PROGRESS' &&
          (booking.parentConfirmedEnd || booking.nannyConfirmedEnd) &&
          !(booking.parentConfirmedEnd && booking.nannyConfirmedEnd)
        ) {
          await this.finalizeSession(bookingId)
          logger.info(`Session end timeout — auto-finalized: ${bookingId}`)
        }
      } catch (err) {
        logger.error('End timeout error', { bookingId, err })
      }
    }, 10 * 60_000) // 10 minutes
  },
}
