import { AppError } from '../../shared/errors/app-error'
import { logger } from '../../shared/utils/logger'
import { parsePagination, paginationMeta } from '../../shared/utils/pagination'
import { nanniesDal } from './nannies.dal'
import { haversineKm } from './nannies.utils'
import type { SearchNanniesInput, UpdateNannyProfileInput } from './nannies.validation'

const orderByMap: Record<string, Record<string, string>> = {
  rating: { rating: 'desc' },
  rate_asc: { hourlyRateNis: 'asc' },
  rate_desc: { hourlyRateNis: 'desc' },
  experience: { yearsExperience: 'desc' },
  reviews: { reviewsCount: 'desc' },
  newest: { createdAt: 'desc' },
}

export const nanniesService = {
  async search(params: SearchNanniesInput) {
    const { city, minRate, maxRate, minYears, language, skill, minRating, lat, lng, radiusKm, sortBy = 'rating', hasRecurringRate } = params as any

    const where: Record<string, unknown> = {}
    if (city) where.city = { contains: city, mode: 'insensitive' }
    if (minRate || maxRate) {
      const r: Record<string, number> = {}
      if (minRate) { const v = parseInt(minRate); if (!isNaN(v)) r.gte = v }
      if (maxRate) { const v = parseInt(maxRate); if (!isNaN(v)) r.lte = v }
      if (Object.keys(r).length) where.hourlyRateNis = r
    }
    if (minYears) { const v = parseInt(minYears); if (!isNaN(v)) where.yearsExperience = { gte: v } }
    if (language) where.languages = { has: language }
    if (skill) where.skills = { has: skill }
    if (minRating) { const v = parseFloat(minRating); if (!isNaN(v)) where.rating = { gte: v } }
    if (hasRecurringRate === 'true') where.recurringHourlyRateNis = { not: null }

    const orderBy = orderByMap[sortBy] || orderByMap['rating']
    const { page, limit, skip } = parsePagination({ page: params.page, limit: params.limit })

    const [profiles, total] = await Promise.all([
      nanniesDal.searchProfiles(where, orderBy, skip, limit),
      nanniesDal.countProfiles(where),
    ])

    let results = profiles.map(p => ({
      ...p,
      distanceKm:
        lat && lng && p.latitude && p.longitude
          ? Math.round(haversineKm(parseFloat(lat), parseFloat(lng), p.latitude, p.longitude) * 10) / 10
          : null,
    }))

    if (lat && lng && radiusKm) {
      const radius = parseFloat(radiusKm)
      results = results.filter(r => r.distanceKm !== null && r.distanceKm <= radius)
    }

    logger.debug('Nanny search', { city, filters: Object.keys(where).length, results: results.length })

    return {
      nannies: results,
      pagination: paginationMeta(total, page, limit),
    }
  },

  async getMyProfile(userId: string) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return profile
  },

  async getById(profileId: string) {
    const profile = await nanniesDal.findById(profileId)
    if (!profile) throw new AppError('Nanny not found', 404)

    const reviews = await nanniesDal.getReviewsForNanny(profile.userId)
    return { profile, reviews }
  },

  async updateMyProfile(userId: string, data: UpdateNannyProfileInput) {
    const { availability, ...profileData } = data
    const profile = await nanniesDal.updateProfile(userId, profileData)

    if (availability) {
      // Group slots by day to support multiple time ranges per day
      const slotsByDay = new Map<number, typeof availability>()
      for (const slot of availability) {
        const existing = slotsByDay.get(slot.dayOfWeek) ?? []
        existing.push(slot)
        slotsByDay.set(slot.dayOfWeek, existing)
      }

      // For each day, delete old slots then create new ones
      for (const [dayOfWeek, daySlots] of slotsByDay) {
        try {
          await nanniesDal.deleteAvailabilityForDay(profile.id, dayOfWeek)
          for (const slot of daySlots) {
            await nanniesDal.upsertAvailability(profile.id, slot)
          }
        } catch (err) {
          logger.error('Failed to update availability slots', {
            userId,
            profileId: profile.id,
            dayOfWeek,
            error: err instanceof Error ? err.message : String(err),
          })
        }
      }
    }

    logger.info('Nanny profile updated', { userId })
    return profile
  },

  async addDocument(userId: string, type: string, url: string) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return nanniesDal.createDocument(profile.id, type, url)
  },

  async getDocuments(userId: string) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return nanniesDal.getDocuments(profile.id)
  },

  async deleteDocument(userId: string, docId: string) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return nanniesDal.deleteDocument(profile.id, docId)
  },

  // ── Date-specific availability ─────────────────────────────
  async upsertDateAvailability(userId: string, data: { date: Date; startTime: string; endTime: string; isBlocked?: boolean }) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return nanniesDal.upsertDateAvailability(profile.id, data)
  },

  async deleteDateAvailability(userId: string, slotId: string) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return nanniesDal.deleteDateAvailability(profile.id, slotId)
  },

  async blockDate(userId: string, date: Date) {
    const profile = await nanniesDal.findByUserId(userId)
    if (!profile) throw new AppError('Profile not found', 404)
    return nanniesDal.blockDate(profile.id, date)
  },

  async getAvailabilityCalendar(nannyProfileId: string, month?: string) {
    const profile = await nanniesDal.findById(nannyProfileId)
    if (!profile) throw new AppError('Nanny not found', 404)

    // Determine date range for the requested month
    let startDate: Date
    let endDate: Date
    if (month) {
      // Validate month format "YYYY-MM"
      const parts = month.split('-')
      if (parts.length !== 2) {
        throw new AppError('Invalid month format. Expected YYYY-MM', 400)
      }
      const year = Number(parts[0])
      const m = Number(parts[1])
      if (isNaN(year) || isNaN(m) || m < 1 || m > 12 || year < 2000 || year > 2100) {
        throw new AppError('Invalid month value', 400)
      }
      startDate = new Date(year, m - 1, 1)
      endDate = new Date(year, m, 0, 23, 59, 59) // last day of month
    } else {
      const now = new Date()
      startDate = new Date(now.getFullYear(), now.getMonth(), 1)
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59)
    }

    // Get date-specific availability slots
    const dateSlots = await nanniesDal.getDateAvailability(profile.id, startDate, endDate)

    // Get existing bookings for this nanny in the range
    const bookings = await nanniesDal.getNannyBookingsForRange(profile.userId, startDate, endDate)

    // Get weekly availability pattern
    const weeklyAvailability = profile.availability || []

    return {
      nannyProfileId: profile.id,
      month: month || `${startDate.getFullYear()}-${String(startDate.getMonth() + 1).padStart(2, '0')}`,
      weeklyAvailability,
      dateSlots,
      bookings,
      minimumHoursPerBooking: profile.minimumHoursPerBooking,
      allowsBabysittingAtHome: profile.allowsBabysittingAtHome,
    }
  },
}
