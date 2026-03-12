import { recurringBookingsDal } from '../modules/recurring-bookings/recurring-bookings.dal'
import { recurringBookingsService } from '../modules/recurring-bookings/recurring-bookings.service'
import { logger } from '../shared/utils/logger'

const GENERATION_WINDOW_DAYS = 7 // generate bookings 7 days ahead

/**
 * Daily job: iterates all ACTIVE recurring bookings and generates
 * individual booking occurrences for the next 7 days.
 *
 * Also auto-ends recurring bookings whose endDate has passed.
 */
export async function runRecurringGeneration(): Promise<void> {
  logger.info('🔄 Starting recurring booking generation job…')

  const activeRecurrings = await recurringBookingsDal.findActiveForGeneration()
  const now = new Date()
  let totalGenerated = 0
  let totalEnded = 0

  for (const rb of activeRecurrings) {
    try {
      // Auto-end if endDate has passed
      if (rb.endDate && rb.endDate < now) {
        await recurringBookingsDal.updateStatus(rb.id, 'ENDED')
        totalEnded++
        logger.info(`⏹  Auto-ended recurring booking ${rb.id} (endDate passed)`)
        continue
      }

      const count = await recurringBookingsService.generateOccurrences(rb.id, GENERATION_WINDOW_DAYS)
      totalGenerated += count
    } catch (err) {
      logger.error(`❌ Error generating for recurring booking ${rb.id}:`, { err })
    }
  }

  logger.info(`✅ Recurring generation complete: ${totalGenerated} bookings created, ${totalEnded} ended`)
}
