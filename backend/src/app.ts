import express from 'express'
import http from 'http'
import cors from 'cors'
import helmet from 'helmet'
import compression from 'compression'
import rateLimit from 'express-rate-limit'
import { Server as SocketIOServer } from 'socket.io'

import { config } from './config'
import { prisma } from './db'
import { logger } from './shared/utils/logger'
import { requestContext } from './shared/middlewares/request-context'
import { errorHandler, notFoundMiddleware } from './shared/middlewares/error.middleware'
import { initSocketIO } from './socket'

// ── Module Routes ───────────────────────────────────────────
import authRoutes    from './modules/auth/auth.routes'
import userRoutes    from './modules/users/users.routes'
import nannyRoutes   from './modules/nannies/nannies.routes'
import bookingRoutes from './modules/bookings/bookings.routes'
import messageRoutes from './modules/messages/messages.routes'
import reviewRoutes  from './modules/reviews/reviews.routes'
import paymentRoutes from './modules/payments/payments.routes'
import adminRoutes   from './modules/admin/admin.routes'
import sessionRoutes   from './modules/sessions/sessions.routes'
import recurringRoutes from './modules/recurring-bookings/recurring-bookings.routes'
import favoritesRoutes from './modules/favorites/favorites.routes'
import verificationRoutes from './modules/verification/verification.routes'

export function createApp() {
  const app = express()
  const httpServer = http.createServer(app)

  const io = new SocketIOServer(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
    pingInterval: 25000,    // send ping every 25s (keep alive through nginx)
    pingTimeout: 20000,     // wait 20s for pong before declaring dead
    connectTimeout: 10000,  // 10s to complete handshake
    transports: ['websocket', 'polling'], // prefer websocket, fallback to polling
  })

  // ── Security ───────────────────────────────────────────
  app.set('trust proxy', 1)
  app.use(helmet())
  app.use(cors({ origin: config.clientUrl, credentials: true }))
  app.use(rateLimit({ windowMs: config.rateLimit.windowMs, max: config.rateLimit.max, standardHeaders: true }))
  // Prevent caching of API responses (stale auth tokens, booking data, etc.)
  app.use('/api', (_req, res, next) => {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
    res.setHeader('Pragma', 'no-cache')
    res.setHeader('Expires', '0')
    next()
  })

  // ── Middleware ─────────────────────────────────────────
  app.use(compression())

  // Request correlation IDs and structured request logging
  app.use(requestContext)

  // Stripe needs raw body — must come before JSON parser
  app.use('/api/payments/webhook', express.raw({ type: 'application/json' }))
  app.use(express.json({ limit: '10mb' }))
  app.use(express.urlencoded({ extended: true }))

  // Static file uploads
  app.use('/uploads', express.static(config.upload.uploadDir))

  // ── Health ─────────────────────────────────────────────
  // Basic health — fast, no DB call (used by mobile connectivity checks)
  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', version: '2.0.0', payments: config.payments.enabled, ts: new Date().toISOString() })
  )

  // Deep health — checks DB, memory, uptime (for monitoring dashboards)
  app.get('/health/deep', async (_req, res) => {
    const mem = process.memoryUsage()
    const uptimeSec = process.uptime()
    let dbOk = false
    let dbLatencyMs = 0
    try {
      const start = Date.now()
      await prisma.$queryRaw`SELECT 1`
      dbLatencyMs = Date.now() - start
      dbOk = true
    } catch (err) {
      logger.error('Deep health: DB unreachable', { error: String(err) })
    }

    const heapUsedMB = Math.round(mem.heapUsed / 1024 / 1024)
    const heapTotalMB = Math.round(mem.heapTotal / 1024 / 1024)
    const heapUsagePercent = heapTotalMB > 0 ? Math.round((heapUsedMB / heapTotalMB) * 100) : 0

    res.status(dbOk ? 200 : 503).json({
      status: dbOk ? 'ok' : 'degraded',
      version: '2.0.0',
      ts: new Date().toISOString(),
      uptime: { seconds: Math.floor(uptimeSec), human: `${Math.floor(uptimeSec / 3600)}h ${Math.floor((uptimeSec % 3600) / 60)}m` },
      database: { connected: dbOk, latencyMs: dbLatencyMs },
      memory: {
        rssMB: Math.round(mem.rss / 1024 / 1024),
        heapUsedMB,
        heapTotalMB,
        heapUsagePercent,
      },
      payments: config.payments.enabled,
      pid: process.pid,
    })
  })

  // ── API Routes ─────────────────────────────────────────
  app.use('/api/auth',     authRoutes)
  app.use('/api/users',    userRoutes)
  app.use('/api/nannies',  nannyRoutes)
  app.use('/api/bookings', bookingRoutes)
  app.use('/api/messages', messageRoutes)
  app.use('/api/reviews',  reviewRoutes)
  app.use('/api/payments', paymentRoutes)
  app.use('/api/admin',    adminRoutes)
  app.use('/api/sessions', sessionRoutes)
  app.use('/api/recurring-bookings', recurringRoutes)
  app.use('/api/favorites', favoritesRoutes)
  app.use('/api/verification-requests', verificationRoutes)

  // ── Socket.IO ──────────────────────────────────────────
  initSocketIO(io)

  // ── Error Handling ─────────────────────────────────────
  app.use(notFoundMiddleware)
  app.use(errorHandler)

  logger.info(`Payments: ${config.payments.enabled ? 'ENABLED (Stripe)' : 'DISABLED (set ENABLE_PAYMENTS=true)'}`)

  return { app, httpServer, io }
}
