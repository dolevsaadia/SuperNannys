import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { adminController } from './admin.controller'

const router = Router()
router.use(requireAuth, requireRole('ADMIN'))

router.get('/stats',                       asyncHandler(adminController.getStats))
router.get('/users',                       asyncHandler(adminController.getUsers))
router.patch('/users/:id',                 asyncHandler(adminController.updateUser))
router.get('/nannies/pending-verification', asyncHandler(adminController.getPendingNannies))
router.get('/bookings',                    asyncHandler(adminController.getBookings))

export default router
