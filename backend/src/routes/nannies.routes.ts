import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, fail, notFound } from '../utils/response'
import { requireAuth, requireRole } from '../middlewares/auth.middleware'

const router = Router()

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

// GET /api/nannies
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const {
    city, minRate, maxRate, minYears, language, skill, minRating,
    lat, lng, radiusKm, page = '1', limit = '20', sortBy = 'rating',
  } = req.query as Record<string, string>

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

  const orderByMap: Record<string, Record<string, string>> = {
    rating: { rating: 'desc' },
    rate_asc: { hourlyRateNis: 'asc' },
    rate_desc: { hourlyRateNis: 'desc' },
    experience: { yearsExperience: 'desc' },
    reviews: { reviewsCount: 'desc' },
    newest: { createdAt: 'desc' },
  }
  const orderBy = orderByMap[sortBy] || orderByMap['rating']

  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(50, Math.max(1, parseInt(limit)))

  const [profiles, total] = await Promise.all([
    prisma.nannyProfile.findMany({
      where,
      orderBy,
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      include: {
        user: { select: { id: true, fullName: true, avatarUrl: true } },
        availability: { orderBy: { dayOfWeek: 'asc' } },
      },
    }),
    prisma.nannyProfile.count({ where }),
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

  ok(res, {
    nannies: results,
    pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) },
  })
})

// GET /api/nannies/me  — own profile (nanny)
router.get('/me', requireAuth, requireRole('NANNY'), async (req: Request, res: Response): Promise<void> => {
  const profile = await prisma.nannyProfile.findUnique({
    where: { userId: req.user!.userId },
    include: { availability: { orderBy: { dayOfWeek: 'asc' } }, documents: true },
  })
  if (!profile) { notFound(res, 'Profile not found'); return }
  ok(res, profile)
})

// GET /api/nannies/:id
router.get('/:id', async (req: Request, res: Response): Promise<void> => {
  const profile = await prisma.nannyProfile.findUnique({
    where: { id: req.params.id },
    include: {
      user: { select: { id: true, fullName: true, avatarUrl: true, createdAt: true } },
      availability: { orderBy: { dayOfWeek: 'asc' } },
      documents: { select: { type: true, verifiedAt: true } },
    },
  })
  if (!profile) { notFound(res); return }

  const reviews = await prisma.review.findMany({
    where: { revieweeUserId: profile.userId },
    orderBy: { createdAt: 'desc' },
    take: 10,
    include: { reviewer: { select: { fullName: true, avatarUrl: true } } },
  })

  ok(res, { profile, reviews })
})

// PUT /api/nannies/me
router.put('/me', requireAuth, requireRole('NANNY'), async (req: Request, res: Response): Promise<void> => {
  const schema = z.object({
    headline: z.string().max(200).optional(),
    bio: z.string().max(2000).optional(),
    hourlyRateNis: z.number().min(20).max(500).optional(),
    yearsExperience: z.number().min(0).max(50).optional(),
    languages: z.array(z.string()).optional(),
    skills: z.array(z.string()).optional(),
    city: z.string().optional(),
    address: z.string().optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    isAvailable: z.boolean().optional(),
    availability: z.array(z.object({
      dayOfWeek: z.number().min(0).max(6),
      fromTime: z.string(),
      toTime: z.string(),
      isAvailable: z.boolean(),
    })).optional(),
  })

  const parse = schema.safeParse(req.body)
  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const { availability, ...profileData } = parse.data
  const profile = await prisma.nannyProfile.update({
    where: { userId: req.user!.userId },
    data: profileData,
  })

  if (availability) {
    for (const slot of availability) {
      await prisma.availability.upsert({
        where: { nannyProfileId_dayOfWeek: { nannyProfileId: profile.id, dayOfWeek: slot.dayOfWeek } },
        update: { fromTime: slot.fromTime, toTime: slot.toTime, isAvailable: slot.isAvailable },
        create: { nannyProfileId: profile.id, ...slot },
      })
    }
  }

  ok(res, profile)
})

export default router
