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
    logger.debug(`Socket connected: ${userId}`)
    socket.join(`user:${userId}`)

    socket.on('booking:join', (bookingId: string) => socket.join(`booking:${bookingId}`))
    socket.on('booking:leave', (bookingId: string) => socket.leave(`booking:${bookingId}`))

    // ── Chat Messages ────────────────────────────────────
    socket.on('message:send', async (payload: { bookingId: string; text: string }) => {
      try {
        if (!payload.bookingId || !payload.text?.trim()) return

        const booking = await messagesDal.findBookingById(payload.bookingId)
        if (!booking) return
        if (booking.parentUserId !== userId && booking.nannyUserId !== userId) return

        const msg = await messagesDal.createMessage(payload.bookingId, userId, payload.text.trim())

        io.to(`booking:${payload.bookingId}`).emit('message:new', msg)

        const recipientId = booking.parentUserId === userId ? booking.nannyUserId : booking.parentUserId
        io.to(`user:${recipientId}`).emit('notification:badge')
      } catch (err) {
        logger.error('socket message error', { err })
      }
    })

    socket.on('typing:start', ({ bookingId }: { bookingId: string }) =>
      socket.to(`booking:${bookingId}`).emit('typing:start', { userId })
    )
    socket.on('typing:stop', ({ bookingId }: { bookingId: string }) =>
      socket.to(`booking:${bookingId}`).emit('typing:stop', { userId })
    )

    // ── Session Events ───────────────────────────────────
    socket.on('session:confirm-start', async ({ bookingId }: { bookingId: string }) => {
      try {
        const result = await sessionsService.confirmStart(userId, socket.role || '', bookingId)
        socket.emit('session:state', result)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to confirm start' })
        logger.error('session confirm-start error', { err })
      }
    })

    socket.on('session:request-end', async ({ bookingId }: { bookingId: string }) => {
      try {
        const result = await sessionsService.requestEnd(userId, socket.role || '', bookingId)
        socket.emit('session:state', result)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to request end' })
        logger.error('session request-end error', { err })
      }
    })

    socket.on('session:confirm-end', async ({ bookingId }: { bookingId: string }) => {
      try {
        const result = await sessionsService.confirmEnd(userId, socket.role || '', bookingId)
        socket.emit('session:state', result)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to confirm end' })
        logger.error('session confirm-end error', { err })
      }
    })

    socket.on('session:get-state', async ({ bookingId }: { bookingId: string }) => {
      try {
        const state = await sessionsService.getState(userId, socket.role || '', bookingId)
        socket.emit('session:state', state)
      } catch (err: any) {
        socket.emit('session:error', { bookingId, message: err.message || 'Failed to get state' })
      }
    })

    socket.on('disconnect', () => logger.debug(`Socket disconnected: ${userId}`))
  })
}
