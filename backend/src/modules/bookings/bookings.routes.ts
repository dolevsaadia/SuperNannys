import { Router } from 'express'
import rateLimit from 'express-rate-limit'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { bookingsController } from './bookings.controller'

const router = Router()
router.use(requireAuth)

// Prevent booking spam — max 10 creations per 5 minutes
const bookingCreateLimit = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  message: { success: false, code: 'RATE_LIMITED', message: 'Too many booking requests. Please wait.' },
})

router.post('/',              bookingCreateLimit, requireRole('PARENT', 'ADMIN'), asyncHandler(bookingsController.create))
router.get('/',               asyncHandler(bookingsController.list))
router.get('/:id',            asyncHandler(bookingsController.getById))
router.patch('/:id/status',   asyncHandler(bookingsController.updateStatus))
router.delete('/:id',         asyncHandler(bookingsController.deleteBooking))

export default router
