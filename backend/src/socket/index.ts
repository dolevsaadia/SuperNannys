import { Server as SocketIOServer, Socket } from 'socket.io'
import { verifyToken } from '../shared/utils/jwt'
import { logger } from '../shared/utils/logger'
import { messagesDal } from '../modules/messages/messages.dal'
import { sessionsService } from '../modules/sessions/sessions.service'
import { sessionTimer } from '../modules/sessions/session-timer'

interface AuthSocket extends Socket {
  userId?: string
  role?: string
}

/** Track which userIds are currently connected (at least one socket). */
const onlineUsers = new Set<string>()

/**
 * Simple per-socket rate limiter for message:send events.
 * Allows `maxMessages` per `windowMs`.
 */
const MESSAGE_RATE_LIMIT = { maxMessages: 30, windowMs: 60_000 }
const messageCounts = new Map<string, { count: number; resetAt: number }>()

function isRateLimited(socketId: string): boolean {
  const now = Date.now()
  let bucket = messageCounts.get(socketId)
  if (!bucket || now >= bucket.resetAt) {
    bucket = { count: 0, resetAt: now + MESSAGE_RATE_LIMIT.windowMs }
    messageCounts.set(socketId, bucket)
  }
  bucket.count++
  return bucket.count > MESSAGE_RATE_LIMIT.maxMessages
}

export function initSocketIO(io: SocketIOServer): void {
  // Give IO reference to sessions module
  sessionsService.setIO(io)

  // Restore timers for any IN_PROGRESS bookings (server restart recovery)
  sessionTimer.restoreTimers()

  // Auth middleware for Socket.IO
  io.use((socket: AuthSocket, next) => {
    const token =
      socket.handshake.auth?.token ||
      (socket.handshake.headers.authorization || '').replace('Bearer ', '')

    if (!token) { next(new Error('Authentication required')); return }
    try {
      const payload = verifyToken(token)
      socket.userId = payload.userId
      socket.role = payload.role
      next()
    } catch {
      next(new Error('Invalid token'))
    }
  })

  io.on('connection', (socket: AuthSocket) => {
    const userId = socket.userId!
    logger.debug('Socket connected', { userId, socketId: socket.id })
    socket.join(`user:${userId}`)
    onlineUsers.add(userId)

    // Broadcast online status to anyone in shared booking rooms
    socket.broadcast.emit('user:online', { userId })

    // Validate bookingId before joining/leaving rooms
    socket.on('booking:join', (bookingId: string) => {
      if (typeof bookingId !== 'string' || !bookingId.trim()) return
      socket.join(`booking:${bookingId}`)
    })
    socket.on('booking:leave', (bookingId: string) => {
      if (typeof bookingId !== 'string' || !bookingId.trim()) return
      socket.leave(`booking:${bookingId}`)
    })

    // ── Online Status Check ──────────────────────────────
    socket.on('user:check-online', (targetUserId: string) => {
      if (typeof targetUserId !== 'string' || !targetUserId) return
      socket.emit('user:online-status', { userId: targetUserId, online: onlineUsers.has(targetUserId) })
    })

    // ── Chat Messages ────────────────────────────────────
    socket.on('message:send', async (payload: { bookingId: string; text: string }) => {
      try {
        if (!payload?.bookingId || !payload?.text?.trim()) return
        if (typeof payload.bookingId !== 'string' || typeof payload.text !== 'string') return

        // Rate limit: 30 messages per minute per socket
        if (isRateLimited(socket.id)) {
          socket.emit('message:error', { message: 'Rate limit exceeded. Please slow down.' })
          logger.warn('Socket message rate limited', { userId, socketId: socket.id })
          return
        }

        const text = payload.text.trim().slice(0, 2000) // enforce max length

        const booking = await messagesDal.findBookingById(payload.bookingId)
        if (!booking) return
        if (booking.parentUserId !== userId && booking.nannyUserId !== userId) return

        const msg = await messagesDal.createMessage(payload.bookingId, userId, text)

        io.to(`booking:${payload.bookingId}`).emit('message:new', msg)

        const recipientId = booking.parentUserId === userId ? booking.nannyUserId : booking.parentUserId
        io.to(`user:${recipientId}`).emit('notification:badge')
      } catch (err) {
        logger.error('Socket message error', { userId, bookingId: payload?.bookingId, err })
      }
    })

    socket.on('typing:start', ({ bookingId }: { bookingId: string }) => {
      if (typeof bookingId !== 'string' || !bookingId) return
      socket.to(`booking:${bookingId}`).emit('typing:start', { userId })
    })
    socket.on('typing:stop', ({ bookingId }: { bookingId: string }) => {
      if (typeof bookingId !== 'string' || !bookingId) return
      socket.to(`booking:${bookingId}`).emit('typing:stop', { userId })
    })

    // ── Session Events ───────────────────────────────────
    socket.on('session:confirm-start', async ({ bookingId }: { bookingId: string }) => {
      if (typeof bookingId !== 'string' || !bookingId) return
      try {
        const result = await sessionsService.confirmStart(userId, socket.role || '', bookingId)
        socket.emit('session:state', result)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to confirm start' })
        logger.error('Session confirm-start error via socket', { userId, bookingId, err: err.message })
      }
    })

    socket.on('session:request-end', async ({ bookingId }: { bookingId: string }) => {
      if (typeof bookingId !== 'string' || !bookingId) return
      try {
        const result = await sessionsService.requestEnd(userId, socket.role || '', bookingId)
        socket.emit('session:state', result)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to request end' })
        logger.error('Session request-end error via socket', { userId, bookingId, err: err.message })
      }
    })

    socket.on('session:confirm-end', async ({ bookingId }: { bookingId: string }) => {
      if (typeof bookingId !== 'string' || !bookingId) return
      try {
        const result = await sessionsService.confirmEnd(userId, socket.role || '', bookingId)
        socket.emit('session:state', result)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to confirm end' })
        logger.error('Session confirm-end error via socket', { userId, bookingId, err: err.message })
      }
    })

    socket.on('session:get-state', async ({ bookingId }: { bookingId: string }) => {
      if (typeof bookingId !== 'string' || !bookingId) return
      try {
        const state = await sessionsService.getState(userId, socket.role || '', bookingId)
        socket.emit('session:state', state)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to get state' })
        logger.error('Session get-state error via socket', { userId, bookingId, err: err.message })
      }
    })

    socket.on('disconnect', () => {
      messageCounts.delete(socket.id)
      // Check if user has any other connected sockets
      const userRoom = io.sockets.adapter.rooms.get(`user:${userId}`)
      if (!userRoom || userRoom.size === 0) {
        onlineUsers.delete(userId)
        socket.broadcast.emit('user:offline', { userId })
      }
      logger.debug('Socket disconnected', { userId, socketId: socket.id })
    })
  })

  // Periodic cleanup of stale rate limit entries (every 5 min)
  setInterval(() => {
    const now = Date.now()
    for (const [key, bucket] of messageCounts) {
      if (now >= bucket.resetAt) messageCounts.delete(key)
    }
  }, 5 * 60_000)
}
