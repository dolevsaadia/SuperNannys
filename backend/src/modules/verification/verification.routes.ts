import { Router } from 'express'
import { requireAuth, requireRole } from '../../shared/middleware/auth'
import { asyncHandler } from '../../shared/middleware/async-handler'
import { verificationController } from './verification.controller'

const router = Router()

// Nanny routes
router.post('/', requireAuth, asyncHandler(verificationController.submit))
router.get('/me', requireAuth, asyncHandler(verificationController.getMyRequest))

// Admin routes
router.get('/all', requireAuth, requireRole('ADMIN'), asyncHandler(verificationController.getAll))
router.patch('/:id', requireAuth, requireRole('ADMIN'), asyncHandler(verificationController.review))

export default router
