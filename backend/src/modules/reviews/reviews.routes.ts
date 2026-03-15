import { Router } from 'express'
import rateLimit from 'express-rate-limit'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { reviewsController } from './reviews.controller'

const router = Router()

// Prevent review spam — max 5 reviews per 10 minutes
const reviewCreateLimit = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  message: { success: false, code: 'RATE_LIMITED', message: 'Too many review submissions.' },
})

router.post('/',                requireAuth, requireRole('PARENT'), reviewCreateLimit, asyncHandler(reviewsController.create))
router.get('/nanny/:userId',    asyncHandler(reviewsController.getByNanny))

export default router
