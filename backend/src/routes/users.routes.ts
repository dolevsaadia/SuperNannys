import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { prisma } from '../db'
import { ok, fail } from '../utils/response'
import { requireAuth } from '../middlewares/auth.middleware'

const router = Router()

// PUT /api/users/me
router.put('/me', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({
    fullName: z.string().min(2).max(100).optional(),
    phone: z.string().optional(),
    avatarUrl: z.string().url().optional().or(z.literal('')),
  }).safeParse(req.body)

  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const user = await prisma.user.update({
    where: { id: req.user!.userId },
    data: parse.data,
    select: { id: true, email: true, fullName: true, phone: true, avatarUrl: true, role: true },
  })
  ok(res, user)
})

// GET /api/users/me/notifications
router.get('/me/notifications', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { page = '1', limit = '20' } = req.query as Record<string, string>
  const pageNum = Math.max(1, parseInt(page))
  const limitNum = Math.min(50, parseInt(limit))

  const [notifications, unreadCount] = await Promise.all([
    prisma.notification.findMany({
      where: { userId: req.user!.userId },
      orderBy: { createdAt: 'desc' },
      skip: (pageNum - 1) * limitNum,
      take: limitNum,
    }),
    prisma.notification.count({ where: { userId: req.user!.userId, isRead: false } }),
  ])

  ok(res, { notifications, unreadCount, pagination: { page: pageNum, limit: limitNum } })
})

// PATCH /api/users/me/notifications/read-all
router.patch('/me/notifications/read-all', requireAuth, async (req: Request, res: Response): Promise<void> => {
  await prisma.notification.updateMany({
    where: { userId: req.user!.userId, isRead: false },
    data: { isRead: true },
  })
  ok(res, { message: 'All notifications marked as read' })
})

// POST /api/users/me/devices
router.post('/me/devices', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const parse = z.object({
    fcmToken: z.string().min(1),
    platform: z.enum(['ios', 'android']),
  }).safeParse(req.body)

  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  await prisma.device.upsert({
    where: { fcmToken: parse.data.fcmToken },
    update: { userId: req.user!.userId },
    create: { userId: req.user!.userId, ...parse.data },
  })
  ok(res, { message: 'Device registered' })
})

// GET /api/users/me/earnings
router.get('/me/earnings', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const earnings = await prisma.earning.findMany({
    where: { nannyUserId: req.user!.userId },
    orderBy: { createdAt: 'desc' },
    include: {
      booking: {
        select: {
          startTime: true, endTime: true,
          parent: { select: { fullName: true, avatarUrl: true } },
        },
      },
    },
  })

  const totalEarned = earnings.reduce((s, e) => s + e.netAmountNis, 0)
  const totalPending = earnings.filter(e => !e.isPaid).reduce((s, e) => s + e.netAmountNis, 0)

  ok(res, { earnings, summary: { totalEarned, totalPending, totalJobs: earnings.length } })
})

export default router
