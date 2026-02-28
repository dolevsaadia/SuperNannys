import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { messagesController } from './messages.controller'

const router = Router()
router.use(requireAuth)

router.get('/conversations',  asyncHandler(messagesController.getConversations))
router.get('/:bookingId',     asyncHandler(messagesController.getMessages))
router.post('/:bookingId',    asyncHandler(messagesController.sendMessage))

export default router
