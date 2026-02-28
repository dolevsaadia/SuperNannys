import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { bookingsController } from './bookings.controller'

const router = Router()
router.use(requireAuth)

router.post('/',              requireRole('PARENT', 'ADMIN'), asyncHandler(bookingsController.create))
router.get('/',               asyncHandler(bookingsController.list))
router.get('/:id',            asyncHandler(bookingsController.getById))
router.patch('/:id/status',   asyncHandler(bookingsController.updateStatus))

export default router
