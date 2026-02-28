import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { reviewsController } from './reviews.controller'

const router = Router()

router.post('/',                requireAuth, requireRole('PARENT'), asyncHandler(reviewsController.create))
router.get('/nanny/:userId',    asyncHandler(reviewsController.getByNanny))

export default router
