import { Router } from 'express'
import rateLimit from 'express-rate-limit'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { messagesController } from './messages.controller'

const router = Router()
router.use(requireAuth)

// Prevent message spam — max 60 messages per minute via REST API
const messageSendLimit = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  standardHeaders: true,
  message: { success: false, code: 'RATE_LIMITED', message: 'Too many messages. Please slow down.' },
})

router.get('/conversations',  asyncHandler(messagesController.getConversations))
router.get('/:bookingId',     asyncHandler(messagesController.getMessages))
router.post('/:bookingId',    messageSendLimit, asyncHandler(messagesController.sendMessage))

export default router
