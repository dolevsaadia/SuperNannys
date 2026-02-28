import { AppError } from '../../shared/errors/app-error'
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

    const where: Record<string, unknown> = {}
    if (city) where.city = { contains: city, mode: 'insensitive' }
    if (minRate || maxRate) {
      const r: Record<string, number> = {}
      if (minRate) r.gte = parseInt(minRate)
      if (maxRate) r.lte = parseInt(maxRate)
      where.hourlyRateNis = r
    }
    if (minYears) where.yearsExperience = { gte: parseInt(minYears) }
    if (language) where.languages = { has: language }
    if (skill) where.skills = { has: skill }
    if (minRating) where.rating = { gte: parseFloat(minRating) }

    const orderBy = orderByMap[sortBy] || orderByMap['rating']
    const pageNum = Math.max(1, parseInt(params.page || '1'))
    const limitNum = Math.min(50, Math.max(1, parseInt(params.limit || '20')))
    const skip = (pageNum - 1) * limitNum

    const [profiles, total] = await Promise.all([
      nanniesDal.searchProfiles(where, orderBy, skip, limitNum),
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

    return {
      nannies: results,
      pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) },
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
      for (const slot of availability) {
        await nanniesDal.upsertAvailability(profile.id, slot)
      }
    }
    return profile
  },
}
