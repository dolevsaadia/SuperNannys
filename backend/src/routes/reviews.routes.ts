import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, created, fail, forbidden, notFound } from '../utils/response'
import { requireAuth, requireRole } from '../middlewares/auth.middleware'

const router = Router()

// POST /api/reviews
router.post('/', requireAuth, requireRole('PARENT'), async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({
    bookingId: z.string(),
    rating: z.number().int().min(1).max(5),
    comment: z.string().max(1000).optional(),
  }).safeParse(req.body)

  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const { bookingId, rating, comment } = parse.data
  const booking = await prisma.booking.findUnique({ where: { id: bookingId } })
  if (!booking) { notFound(res, 'Booking not found'); return }
  if (booking.parentUserId !== req.user!.userId) { forbidden(res); return }
  if (booking.status !== 'COMPLETED') { fail(res, 'Can only review completed bookings'); return }
  if (await prisma.review.findUnique({ where: { bookingId } })) { fail(res, 'Review already submitted', 409); return }

  const review = await prisma.review.create({
    data: { bookingId, reviewerUserId: req.user!.userId, revieweeUserId: booking.nannyUserId, rating, comment },
  })

  const stats = await prisma.review.aggregate({
    where: { revieweeUserId: booking.nannyUserId },
    _avg: { rating: true },
    _count: true,
  })

  await prisma.nannyProfile.update({
    where: { userId: booking.nannyUserId },
    data: {
      rating: Math.round((stats._avg.rating || 0) * 10) / 10,
      reviewsCount: stats._count,
    },
  })

  created(res, review)
})

// GET /api/reviews/nanny/:userId
router.get('/nanny/:userId', async (req: Request, res: Response): Promise<void> => {
  const { page = '1', limit = '10' } = req.query as Record<string, string>
  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(50, parseInt(limit))

  const [reviews, total] = await Promise.all([
    prisma.review.findMany({
      where: { revieweeUserId: req.params.userId },
      orderBy: { createdAt: 'desc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      include: { reviewer: { select: { fullName: true, avatarUrl: true } } },
    }),
    prisma.review.count({ where: { revieweeUserId: req.params.userId } }),
  ])

  ok(res, { reviews, pagination: { total, page: pageNum, limit: limitNum } })
})

export default router
