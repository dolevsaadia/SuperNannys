import { recurringBookingsDal } from '../modules/recurring-bookings/recurring-bookings.dal'
import { recurringBookingsService } from '../modules/recurring-bookings/recurring-bookings.service'
import { logger } from '../shared/utils/logger'

const GENERATION_WINDOW_DAYS = 7

/**
 * Simple in-process lock to prevent overlapping runs.
 * If the job is already running, a new invocation is skipped.
 */
let isRunning = false

/**
 * Daily job: iterates all ACTIVE recurring bookings and generates
 * individual booking occurrences for the next 7 days.
 *
 * Also auto-ends recurring bookings whose endDate has passed.
 *
 * Features:
 * - In-process mutex prevents overlapping runs
 * - Per-item error isolation (one failure doesn't stop others)
 * - Structured logging with timing and metrics
 */
export async function runRecurringGeneration(): Promise<void> {
  if (isRunning) {
    logger.warn('Recurring generation skipped — previous run still in progress')
    return
  }

  isRunning = true
  const startTime = Date.now()
  logger.info('Recurring generation job started')

  try {
    const activeRecurrings = await recurringBookingsDal.findActiveForGeneration()
    const now = new Date()
    let totalGenerated = 0
    let totalEnded = 0
    let totalErrors = 0
    const errorDetails: Array<{ id: string; error: string }> = []

    for (const rb of activeRecurrings) {
      try {
        // Auto-end if endDate has passed
        if (rb.endDate && rb.endDate < now) {
          await recurringBookingsDal.updateStatus(rb.id, 'ENDED')
          totalEnded++
          logger.info('Auto-ended recurring booking', { recurringBookingId: rb.id, reason: 'endDate_passed' })
          continue
        }

        const count = await recurringBookingsService.generateOccurrences(rb.id, GENERATION_WINDOW_DAYS)
        totalGenerated += count
      } catch (err) {
        totalErrors++
        const errMsg = err instanceof Error ? err.message : String(err)
        errorDetails.push({ id: rb.id, error: errMsg })
        logger.error('Error generating for recurring booking', {
          recurringBookingId: rb.id,
          error: errMsg,
        })
      }
    }

    const durationMs = Date.now() - startTime
    logger.info('Recurring generation job completed', {
      totalActive: activeRecurrings.length,
      totalGenerated,
      totalEnded,
      totalErrors,
      durationMs,
      ...(errorDetails.length > 0 ? { errorDetails: errorDetails.slice(0, 10) } : {}),
    })
  } catch (err) {
    logger.error('Recurring generation job failed entirely', {
      error: err instanceof Error ? err.message : String(err),
      durationMs: Date.now() - startTime,
    })
  } finally {
    isRunning = false
  }
}
