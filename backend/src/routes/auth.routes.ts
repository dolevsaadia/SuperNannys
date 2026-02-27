import { Router, Request, Response } from 'express'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { OAuth2Client } from 'google-auth-library'
import { prisma } from '../db'
import { signToken } from '../utils/jwt'
import { ok, created, fail, unauthorized } from '../utils/response'
import { config } from '../config'
import { requireAuth } from '../middlewares/auth.middleware'

const router = Router()
const googleClient = new OAuth2Client(config.google.clientId)

const registerSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  fullName: z.string().min(2).max(100),
  phone: z.string().optional(),
  role: z.enum(['PARENT', 'NANNY']),
})

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
})

// POST /api/auth/register
router.post('/register', async (req: Request, res: Response): Promise<void> => {
  const parse = registerSchema.safeParse(req.body)
  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const { email, password, fullName, phone, role } = parse.data
  const existing = await prisma.user.findUnique({ where: { email } })
  if (existing) { fail(res, 'Email already in use', 409); return }

  const passwordHash = await bcrypt.hash(password, 12)
  const user = await prisma.user.create({
    data: { email, passwordHash, fullName, phone, role },
    select: { id: true, email: true, fullName: true, role: true, avatarUrl: true, isVerified: true, phone: true },
  })

  if (role === 'NANNY') {
    await prisma.nannyProfile.create({ data: { userId: user.id } })
  }

  const token = signToken({ userId: user.id, email: user.email, role: user.role })
  created(res, { token, user })
})

// POST /api/auth/login
router.post('/login', async (req: Request, res: Response): Promise<void> => {
  const parse = loginSchema.safeParse(req.body)
  if (!parse.success) { fail(res, 'Validation failed', 400, parse.error.flatten()); return }

  const { email, password } = parse.data
  const user = await prisma.user.findUnique({ where: { email } })
  if (!user || !user.passwordHash) { unauthorized(res, 'Invalid credentials'); return }
  if (!user.isActive) { fail(res, 'Account deactivated', 403); return }

  const valid = await bcrypt.compare(password, user.passwordHash)
  if (!valid) { unauthorized(res, 'Invalid credentials'); return }

  const token = signToken({ userId: user.id, email: user.email, role: user.role })
  ok(res, {
    token,
    user: { id: user.id, email: user.email, fullName: user.fullName, role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified },
  })
})

// POST /api/auth/google
router.post('/google', async (req: Request, res: Response): Promise<void> => {
  const { idToken, role } = req.body as { idToken?: string; role?: string }
  if (!idToken) { fail(res, 'idToken required'); return }

  try {
    const ticket = await googleClient.verifyIdToken({ idToken, audience: config.google.clientId })
    const payload = ticket.getPayload()
    if (!payload?.email) { fail(res, 'Invalid Google token'); return }

    let user = await prisma.user.findFirst({
      where: { OR: [{ googleSub: payload.sub }, { email: payload.email }] },
    })

    if (!user) {
      const userRole = (role as 'PARENT' | 'NANNY') || 'PARENT'
      user = await prisma.user.create({
        data: {
          email: payload.email,
          fullName: payload.name || payload.email,
          avatarUrl: payload.picture,
          role: userRole,
          authProvider: 'GOOGLE',
          googleSub: payload.sub,
          isVerified: true,
        },
      })
      if (userRole === 'NANNY') {
        await prisma.nannyProfile.create({ data: { userId: user.id } })
      }
    } else if (!user.googleSub) {
      user = await prisma.user.update({ where: { id: user.id }, data: { googleSub: payload.sub, authProvider: 'GOOGLE' } })
    }

    const token = signToken({ userId: user.id, email: user.email, role: user.role })
    ok(res, {
      token,
      user: { id: user.id, email: user.email, fullName: user.fullName, role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified },
    })
  } catch {
    fail(res, 'Google authentication failed', 401)
  }
})

// GET /api/auth/me
router.get('/me', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.userId },
    select: {
      id: true, email: true, fullName: true, phone: true, role: true,
      avatarUrl: true, isVerified: true, createdAt: true,
      nannyProfile: {
        select: {
          id: true, headline: true, hourlyRateNis: true, rating: true, reviewsCount: true,
          isVerified: true, isAvailable: true, city: true, badges: true, completedJobs: true, totalEarnings: true,
        },
      },
    },
  })
  if (!user) { fail(res, 'User not found', 404); return }
  ok(res, user)
})

export default router
