import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, fail } from '../utils/response'
import { requireAuth, requireRole } from '../middlewares/auth.middleware'

const router = Router()
router.use(requireAuth, requireRole('ADMIN'))

// GET /api/admin/stats
router.get('/stats', async (_req: Request, res: Response): Promise<void> => {
  const [totalUsers, totalNannies, totalParents, totalBookings, pendingBookings, completedBookings, revenueAgg] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { role: 'NANNY' } }),
    prisma.user.count({ where: { role: 'PARENT' } }),
    prisma.booking.count(),
    prisma.booking.count({ where: { status: 'REQUESTED' } }),
    prisma.booking.count({ where: { status: 'COMPLETED' } }),
    prisma.earning.aggregate({ _sum: { platformFee: true, amountNis: true } }),
  ])

  ok(res, {
    users: { total: totalUsers, nannies: totalNannies, parents: totalParents },
    bookings: { total: totalBookings, pending: pendingBookings, completed: completedBookings },
    revenue: {
      platformFees: revenueAgg._sum.platformFee || 0,
      grossVolume: revenueAgg._sum.amountNis || 0,
    },
  })
})

// GET /api/admin/users
router.get('/users', async (req: Request, res: Response): Promise<void> => {
  const { search, role, isActive, page = '1', limit = '20' } = req.query as Record<string, string>
  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(100, parseInt(limit))

  const where: Record<string, unknown> = {}
  if (role) where.role = role
  if (isActive !== undefined) where.isActive = isActive === 'true'
  if (search) {
    where.OR = [
      { fullName: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
    ]
  }

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      select: {
        id: true, email: true, fullName: true, role: true,
        isActive: true, isVerified: true, createdAt: true, phone: true,
        _count: { select: { parentBookings: true, nannyBookings: true } },
      },
    }),
    prisma.user.count({ where }),
  ])

  ok(res, { users, pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) } })
})

// PATCH /api/admin/users/:id
router.patch('/users/:id', async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({
    isActive: z.boolean().optional(),
    isVerified: z.boolean().optional(),
    role: z.enum(['PARENT', 'NANNY', 'ADMIN']).optional(),
  }).safeParse(req.body)

  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const user = await prisma.user.update({
    where: { id: req.params.id },
    data: parse.data,
    select: { id: true, email: true, fullName: true, role: true, isActive: true, isVerified: true },
  })
  ok(res, user)
})

// GET /api/admin/nannies/pending-verification
router.get('/nannies/pending-verification', async (req: Request, res: Response): Promise<void> => {
  const { page = '1', limit = '20' } = req.query as Record<string, string>
  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(100, parseInt(limit))

  const where = { role: 'NANNY' as const, isVerified: false, isActive: true }

  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      select: {
        id: true, email: true, fullName: true, phone: true,
        isVerified: true, createdAt: true, avatarUrl: true,
        nannyProfile: {
          select: {
            headline: true, hourlyRateNis: true, city: true,
            yearsExperience: true, languages: true, skills: true,
            completedJobs: true, rating: true, reviewsCount: true,
          },
        },
      },
    }),
    prisma.user.count({ where }),
  ])

  ok(res, { nannies: users, pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) } })
})

// GET /api/admin/bookings
router.get('/bookings', async (req: Request, res: Response): Promise<void> => {
  const { status, page = '1', limit = '20' } = req.query as Record<string, string>
  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(100, parseInt(limit))

  const where: Record<string, unknown> = {}
  if (status) where.status = status

  const [bookings, total] = await Promise.all([
    prisma.booking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      include: {
        parent: { select: { fullName: true, email: true } },
        nanny: { select: { fullName: true, email: true } },
      },
    }),
    prisma.booking.count({ where }),
  ])

  ok(res, { bookings, pagination: { total, page: pageNum, limit: limitNum } })
})

export default router
