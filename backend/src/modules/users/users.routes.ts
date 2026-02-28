import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { usersController } from './users.controller'

const router = Router()
router.use(requireAuth)

router.put('/me',                         asyncHandler(usersController.updateProfile))
router.get('/me/notifications',           asyncHandler(usersController.getNotifications))
router.patch('/me/notifications/read-all', asyncHandler(usersController.markAllNotificationsRead))
router.post('/me/devices',                asyncHandler(usersController.registerDevice))
router.get('/me/earnings',                asyncHandler(usersController.getEarnings))

export default router
