import express from 'express'
import http from 'http'
import cors from 'cors'
import helmet from 'helmet'
import compression from 'compression'
import rateLimit from 'express-rate-limit'
import { Server as SocketIOServer } from 'socket.io'

import { config } from './config'
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
    cors: { origin: config.clientUrl, methods: ['GET', 'POST'], credentials: true },
    pingTimeout: 60000,
  })

  // ── Security ───────────────────────────────────────────
  app.set('trust proxy', 1)
  app.use(helmet())
  app.use(cors({ origin: config.clientUrl, credentials: true }))
  app.use(rateLimit({ windowMs: config.rateLimit.windowMs, max: config.rateLimit.max, standardHeaders: true }))

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
  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', version: '1.5.1', payments: config.payments.enabled, ts: new Date().toISOString() })
  )

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
