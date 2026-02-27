import express from 'express'
import http from 'http'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import compression from 'compression'
import rateLimit from 'express-rate-limit'
import { Server as SocketIOServer } from 'socket.io'

import { config } from './config'
import { logger } from './utils/logger'
import { errorHandler, notFoundMiddleware } from './middlewares/error.middleware'
import { initSocketIO } from './socket'

import authRoutes from './routes/auth.routes'
import nannyRoutes from './routes/nannies.routes'
import bookingRoutes from './routes/bookings.routes'
import messageRoutes from './routes/messages.routes'
import reviewRoutes from './routes/reviews.routes'
import userRoutes from './routes/users.routes'
import adminRoutes from './routes/admin.routes'
import paymentRoutes from './routes/payments.routes'

export function createApp() {
  const app = express()
  const httpServer = http.createServer(app)

  const io = new SocketIOServer(httpServer, {
    cors: { origin: config.clientUrl, methods: ['GET', 'POST'], credentials: true },
    pingTimeout: 60000,
  })

  // ── Security ───────────────────────────────────────────
  app.use(helmet())
  app.use(cors({ origin: config.clientUrl, credentials: true }))
  app.use(rateLimit({ windowMs: config.rateLimit.windowMs, max: config.rateLimit.max, standardHeaders: true }))

  // ── Middleware ─────────────────────────────────────────
  app.use(compression())
  app.use(morgan('dev'))

  // Stripe needs raw body
  app.use('/api/payments/webhook', express.raw({ type: 'application/json' }))
  app.use(express.json({ limit: '10mb' }))
  app.use(express.urlencoded({ extended: true }))

  // Static file uploads
  app.use('/uploads', express.static(config.upload.uploadDir))

  // ── Health ─────────────────────────────────────────────
  app.get('/health', (_req, res) =>
    res.json({ status: 'ok', version: '1.0.0', payments: config.payments.enabled, ts: new Date().toISOString() })
  )

  // ── API Routes ─────────────────────────────────────────
  app.use('/api/auth', authRoutes)
  app.use('/api/nannies', nannyRoutes)
  app.use('/api/bookings', bookingRoutes)
  app.use('/api/messages', messageRoutes)
  app.use('/api/reviews', reviewRoutes)
  app.use('/api/users', userRoutes)
  app.use('/api/admin', adminRoutes)
  app.use('/api/payments', paymentRoutes)

  // ── Socket.IO ──────────────────────────────────────────
  initSocketIO(io)

  // ── Error Handling ─────────────────────────────────────
  app.use(notFoundMiddleware)
  app.use(errorHandler)

  logger.info(`💳 Payments: ${config.payments.enabled ? 'ENABLED (Stripe)' : 'DISABLED (set ENABLE_PAYMENTS=true)'}`)

  return { app, httpServer, io }
}
