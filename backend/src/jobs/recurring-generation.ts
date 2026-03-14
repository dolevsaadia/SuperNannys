import { recurringBookingsDal } from '../modules/recurring-bookings/recurring-bookings.dal'
import { recurringBookingsService } from '../modules/recurring-bookings/recurring-bookings.service'
import { logger } from '../shared/utils/logger'

const GENERATION_WINDOW_DAYS = 7

/**
 * Daily job: iterates all ACTIVE recurring bookings and generates
 * individual booking occurrences for the next 7 days.
 *
 * Also auto-ends recurring bookings whose endDate has passed.
 */
export async function runRecurringGeneration(): Promise<void> {
  const startTime = Date.now()
  logger.info('Recurring generation job started')

  try {
    const activeRecurrings = await recurringBookingsDal.findActiveForGeneration()
    const now = new Date()
    let totalGenerated = 0
    let totalEnded = 0
    let totalErrors = 0

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
        logger.error('Error generating for recurring booking', { recurringBookingId: rb.id, err })
      }
    }

    const durationMs = Date.now() - startTime
    logger.info('Recurring generation job completed', {
      totalActive: activeRecurrings.length,
      totalGenerated,
      totalEnded,
      totalErrors,
      durationMs,
    })
  } catch (err) {
    logger.error('Recurring generation job failed entirely', { err, durationMs: Date.now() - startTime })
  }
}
