import { Server as SocketIOServer, Socket } from 'socket.io'
import { verifyToken } from '../utils/jwt'
import { prisma } from '../db'
import { logger } from '../utils/logger'

interface AuthSocket extends Socket {
  userId?: string
  role?: string
}

export function initSocketIO(io: SocketIOServer): void {
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

    socket.on('message:send', async (payload: { bookingId: string; text: string }) => {
      try {
        if (!payload.bookingId || !payload.text?.trim()) return
        const booking = await prisma.booking.findUnique({ where: { id: payload.bookingId } })
        if (!booking) return
        if (booking.parentUserId !== userId && booking.nannyUserId !== userId) return

        const msg = await prisma.message.create({
          data: { bookingId: payload.bookingId, fromUserId: userId, text: payload.text.trim() },
          include: { from: { select: { id: true, fullName: true, avatarUrl: true } } },
        })

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

    socket.on('disconnect', () => logger.debug(`Socket disconnected: ${userId}`))
  })
}
