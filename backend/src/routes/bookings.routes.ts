import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, created, fail, notFound, forbidden } from '../utils/response'
import { requireAuth, requireRole } from '../middlewares/auth.middleware'
import { config } from '../config'

const router = Router()

// POST /api/bookings
router.post('/', requireAuth, requireRole('PARENT', 'ADMIN'), async (req: Request, res: Response): Promise<void> => {
  const schema = z.object({
    nannyUserId: z.string(),
    startTime: z.string().datetime(),
    endTime: z.string().datetime(),
    notes: z.string().max(500).optional(),
    childrenCount: z.number().int().min(1).max(10).default(1),
    childrenAges: z.array(z.string()).optional(),
    address: z.string().optional(),
  })

  const parse = schema.safeParse(req.body)
  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const { nannyUserId, startTime, endTime, ...rest } = parse.data
  const start = new Date(startTime)
  const end = new Date(endTime)

  if (end <= start) { fail(res, 'End time must be after start time'); return }

  const nannyProfile = await prisma.nannyProfile.findUnique({ where: { userId: nannyUserId } })
  if (!nannyProfile) { notFound(res, 'Nanny not found'); return }

  const conflict = await prisma.booking.findFirst({
    where: {
      nannyUserId,
      status: { in: ['REQUESTED', 'ACCEPTED', 'IN_PROGRESS'] },
      startTime: { lt: end },
      endTime: { gt: start },
    },
  })
  if (conflict) { fail(res, 'Nanny is not available for this time slot', 409); return }

  const durationHours = (end.getTime() - start.getTime()) / 3_600_000
  const totalAmountNis = Math.round(durationHours * nannyProfile.hourlyRateNis)

  const booking = await prisma.booking.create({
    data: {
      parentUserId: req.user!.userId,
      nannyUserId,
      startTime: start,
      endTime: end,
      hourlyRateNis: nannyProfile.hourlyRateNis,
      totalAmountNis,
      ...rest,
    },
    include: {
      parent: { select: { fullName: true, avatarUrl: true, phone: true } },
      nanny: { select: { fullName: true, avatarUrl: true, phone: true } },
    },
  })

  created(res, booking)
})

// GET /api/bookings
router.get('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { status, page = '1', limit = '20' } = req.query as Record<string, string>
  const userId = req.user!.userId
  const role = req.user!.role

  const where: Record<string, unknown> =
    role === 'PARENT' ? { parentUserId: userId } :
    role === 'NANNY'  ? { nannyUserId: userId } : {}

  if (status) where.status = status

  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(50, parseInt(limit))

  const [bookings, total] = await Promise.all([
    prisma.booking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      include: {
        parent: { select: { id: true, fullName: true, avatarUrl: true } },
        nanny: { select: { id: true, fullName: true, avatarUrl: true } },
        review: { select: { rating: true, comment: true } },
        _count: { select: { messages: true } },
      },
    }),
    prisma.booking.count({ where }),
  ])

  ok(res, { bookings, pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) } })
})

// GET /api/bookings/:id
router.get('/:id', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id },
    include: {
      parent: { select: { id: true, fullName: true, avatarUrl: true, phone: true } },
      nanny: {
        select: {
          id: true, fullName: true, avatarUrl: true, phone: true,
          nannyProfile: { select: { hourlyRateNis: true, city: true, rating: true, badges: true } },
        },
      },
      review: true,
      earning: { select: { netAmountNis: true, isPaid: true } },
    },
  })
  if (!booking) { notFound(res); return }

  const userId = req.user!.userId
  if (booking.parentUserId !== userId && booking.nannyUserId !== userId && req.user!.role !== 'ADMIN') {
    forbidden(res)
    return
  }
  ok(res, booking)
})

// PATCH /api/bookings/:id/status
router.patch('/:id/status', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({ status: z.enum(['ACCEPTED', 'DECLINED', 'CANCELLED', 'COMPLETED']) }).safeParse(req.body)
  if (!parse.success) { fail(res, 'Invalid status'); return }

  const booking = await prisma.booking.findUnique({ where: { id: req.params.id } })
  if (!booking) { notFound(res); return }

  const userId = req.user!.userId
  const { status } = parse.data

  if ((status === 'ACCEPTED' || status === 'DECLINED') && booking.nannyUserId !== userId) {
    forbidden(res, 'Only the nanny can accept/decline'); return
  }
  if (status === 'CANCELLED' && booking.parentUserId !== userId && booking.nannyUserId !== userId) {
    forbidden(res); return
  }
  if (status === 'COMPLETED' && booking.nannyUserId !== userId) {
    forbidden(res, 'Only the nanny can mark completed'); return
  }

  const updated = await prisma.booking.update({ where: { id: req.params.id }, data: { status } })

  if (status === 'COMPLETED') {
    const platformFee = Math.round(updated.totalAmountNis * config.platformFeePercent / 100)
    await prisma.earning.upsert({
      where: { bookingId: updated.id },
      update: {},
      create: {
        nannyUserId: updated.nannyUserId,
        bookingId: updated.id,
        amountNis: updated.totalAmountNis,
        platformFee,
        netAmountNis: updated.totalAmountNis - platformFee,
      },
    })
    await prisma.nannyProfile.update({
      where: { userId: updated.nannyUserId },
      data: {
        completedJobs: { increment: 1 },
        totalEarnings: { increment: updated.totalAmountNis - platformFee },
      },
    })
  }

  ok(res, updated)
})

export default router
