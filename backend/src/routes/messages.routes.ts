import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, created, fail, forbidden, notFound } from '../utils/response'
import { requireAuth } from '../middlewares/auth.middleware'

const router = Router()

// GET /api/messages/conversations
router.get('/conversations', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const userId = req.user!.userId
  const role = req.user!.role

  const bookings = await prisma.booking.findMany({
    where: role === 'PARENT' ? { parentUserId: userId } : { nannyUserId: userId },
    orderBy: { updatedAt: 'desc' },
    include: {
      parent: { select: { id: true, fullName: true, avatarUrl: true } },
      nanny: { select: { id: true, fullName: true, avatarUrl: true } },
      messages: { orderBy: { createdAt: 'desc' }, take: 1 },
      _count: {
        select: { messages: { where: { isRead: false, fromUserId: { not: userId } } } },
      },
    },
  })

  ok(res, bookings)
})

// GET /api/messages/:bookingId
router.get('/:bookingId', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const booking = await prisma.booking.findUnique({ where: { id: req.params.bookingId } })
  if (!booking) { notFound(res); return }

  const userId = req.user!.userId
  if (booking.parentUserId !== userId && booking.nannyUserId !== userId) { forbidden(res); return }

  const { page = '1', limit = '50' } = req.query as Record<string, string>
  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(100, parseInt(limit))

  const [messages, total] = await Promise.all([
    prisma.message.findMany({
      where: { bookingId: req.params.bookingId },
      orderBy: { createdAt: 'asc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
      include: { from: { select: { id: true, fullName: true, avatarUrl: true } } },
    }),
    prisma.message.count({ where: { bookingId: req.params.bookingId } }),
  ])

  // Mark as read
  await prisma.message.updateMany({
    where: { bookingId: req.params.bookingId, fromUserId: { not: userId }, isRead: false },
    data: { isRead: true },
  })

  ok(res, { messages, pagination: { total, page: pageNum, limit: limitNum } })
})

// POST /api/messages/:bookingId
router.post('/:bookingId', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({ text: z.string().min(1).max(2000) }).safeParse(req.body)
  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const booking = await prisma.booking.findUnique({ where: { id: req.params.bookingId } })
  if (!booking) { notFound(res); return }

  const userId = req.user!.userId
  if (booking.parentUserId !== userId && booking.nannyUserId !== userId) { forbidden(res); return }

  const message = await prisma.message.create({
    data: { bookingId: booking.id, fromUserId: userId, text: parse.data.text },
    include: { from: { select: { id: true, fullName: true, avatarUrl: true } } },
  })

  created(res, message)
})

export default router
