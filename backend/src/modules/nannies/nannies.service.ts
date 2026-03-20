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
    const { city, minRate, maxRate, minYears, language, skill, minRating, lat, lng, radiusKm, sortBy = 'rating' } = params

    const where: Record<string, unknown> = {
      // Only show nannies whose user account is verified and active
      user: { isVerified: true, isActive: true },
    }
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
    await nanniesDal.updateProfile(userId, profileData)

    if (availability) {
      // Get the profile id for availability upserts
      const existing = await nanniesDal.findByUserId(userId)
      if (existing) {
        for (const slot of availability) {
          try {
            await nanniesDal.upsertAvailability(existing.id, slot)
          } catch (err) {
            logger.error('Failed to upsert availability slot', {
              userId,
              profileId: existing.id,
              dayOfWeek: slot.dayOfWeek,
              error: err instanceof Error ? err.message : String(err),
            })
          }
        }
      }
    }

    logger.info('Nanny profile updated', { userId })
    // Return full profile with availability included
    return nanniesDal.findByUserId(userId)
  },
}
