import { Server as SocketIOServer } from 'socket.io'
import { logger } from '../../shared/utils/logger'
import { sessionsDal } from './sessions.dal'

interface ActiveTimer {
  interval: NodeJS.Timeout
  bookingId: string
  startTime: Date
  bookedDurationMin: number
  hourlyRateNis: number
}

const timers = new Map<string, ActiveTimer>()

let ioRef: SocketIOServer | null = null

export const sessionTimer = {
  /** Set IO reference for emitting events */
  setIO(io: SocketIOServer) {
    ioRef = io
  },

  /** Start a timer for a booking */
  start(bookingId: string, startTime: Date, bookedDurationMin: number, hourlyRateNis: number) {
    // Clear any existing timer
    this.stop(bookingId)

    const interval = setInterval(() => {
      this.tick(bookingId)
    }, 30_000) // every 30 seconds

    timers.set(bookingId, {
      interval,
      bookingId,
      startTime,
      bookedDurationMin,
      hourlyRateNis,
    })

    logger.info(`Session timer started: ${bookingId}`)

    // Emit first tick immediately
    this.tick(bookingId)
  },

  /** Stop and remove a timer */
  stop(bookingId: string) {
    const timer = timers.get(bookingId)
    if (timer) {
      clearInterval(timer.interval)
      timers.delete(bookingId)
      logger.info(`Session timer stopped: ${bookingId}`)
    }
  },

  /** Emit tick data to booking room */
  tick(bookingId: string) {
    const timer = timers.get(bookingId)
    if (!timer || !ioRef) return

    const now = new Date()
    const elapsedMs = now.getTime() - timer.startTime.getTime()
    const elapsedSeconds = Math.floor(elapsedMs / 1000)
    const elapsedMin = elapsedMs / 60_000
    const isOvertime = elapsedMin > timer.bookedDurationMin

    let currentAmountNis: number
    if (!isOvertime) {
      // Within booked time — charge original amount
      currentAmountNis = Math.round((timer.bookedDurationMin / 60) * timer.hourlyRateNis)
    } else {
      // Overtime — base + extra time at hourly rate
      const baseAmount = Math.round((timer.bookedDurationMin / 60) * timer.hourlyRateNis)
      const overtimeMin = elapsedMin - timer.bookedDurationMin
      // Round overtime to nearest 15 min block
      const overtimeBlocks = Math.ceil(overtimeMin / 15)
      const overtimeAmount = Math.round((overtimeBlocks * 15 / 60) * timer.hourlyRateNis)
      currentAmountNis = baseAmount + overtimeAmount
    }

    ioRef.to(`booking:${bookingId}`).emit('session:tick', {
      bookingId,
      elapsedSeconds,
      isOvertime,
      currentAmountNis,
      bookedDurationMin: timer.bookedDurationMin,
    })
  },

  /** Calculate final amounts when session ends */
  calculateFinal(bookingId: string): {
    actualDurationMin: number
    finalAmountNis: number
    overtimeAmountNis: number
  } | null {
    const timer = timers.get(bookingId)
    if (!timer) return null

    const now = new Date()
    const elapsedMs = now.getTime() - timer.startTime.getTime()
    const actualDurationMin = Math.round(elapsedMs / 60_000)
    const baseAmount = Math.round((timer.bookedDurationMin / 60) * timer.hourlyRateNis)

    let finalAmountNis: number
    let overtimeAmountNis: number

    if (actualDurationMin <= timer.bookedDurationMin) {
      // Finished early or on time — charge original booked price
      finalAmountNis = baseAmount
      overtimeAmountNis = 0
    } else {
      // Overtime — charge extra (rounded up to 15 min blocks)
      const overtimeMin = actualDurationMin - timer.bookedDurationMin
      const overtimeBlocks = Math.ceil(overtimeMin / 15)
      overtimeAmountNis = Math.round((overtimeBlocks * 15 / 60) * timer.hourlyRateNis)
      finalAmountNis = baseAmount + overtimeAmountNis
    }

    return { actualDurationMin, finalAmountNis, overtimeAmountNis }
  },

  /** Get current state of a timer (for reconnect/sync) */
  getState(bookingId: string) {
    const timer = timers.get(bookingId)
    if (!timer) return null

    const now = new Date()
    const elapsedMs = now.getTime() - timer.startTime.getTime()
    const elapsedSeconds = Math.floor(elapsedMs / 1000)
    const elapsedMin = elapsedMs / 60_000
    const isOvertime = elapsedMin > timer.bookedDurationMin

    let currentAmountNis: number
    if (!isOvertime) {
      currentAmountNis = Math.round((timer.bookedDurationMin / 60) * timer.hourlyRateNis)
    } else {
      const baseAmount = Math.round((timer.bookedDurationMin / 60) * timer.hourlyRateNis)
      const overtimeMin = elapsedMin - timer.bookedDurationMin
      const overtimeBlocks = Math.ceil(overtimeMin / 15)
      const overtimeAmount = Math.round((overtimeBlocks * 15 / 60) * timer.hourlyRateNis)
      currentAmountNis = baseAmount + overtimeAmount
    }

    return {
      bookingId,
      elapsedSeconds,
      isOvertime,
      currentAmountNis,
      bookedDurationMin: timer.bookedDurationMin,
      startTime: timer.startTime.toISOString(),
    }
  },

  /** Restore timers for IN_PROGRESS bookings on server restart */
  async restoreTimers() {
    try {
      const activeSessions = await sessionsDal.findAllActiveSessions()
      for (const booking of activeSessions) {
        if (!booking.actualStartTime) continue

        const bookedDurationMin = Math.round(
          (new Date(booking.endTime).getTime() - new Date(booking.startTime).getTime()) / 60_000
        )

        this.start(
          booking.id,
          new Date(booking.actualStartTime),
          bookedDurationMin,
          booking.hourlyRateNis,
        )
      }
      if (activeSessions.length > 0) {
        logger.info(`Restored ${activeSessions.length} session timer(s)`)
      }
    } catch (err) {
      logger.error('Failed to restore session timers', { err })
    }
  },

  /** Check if a timer exists */
  has(bookingId: string) {
    return timers.has(bookingId)
  },
}
