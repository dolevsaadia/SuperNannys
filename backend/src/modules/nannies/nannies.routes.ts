import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { nanniesController } from './nannies.controller'

const router = Router()

router.get('/',    asyncHandler(nanniesController.search))
router.get('/me',  requireAuth, requireRole('NANNY'), asyncHandler(nanniesController.getMyProfile))
router.get('/:id', asyncHandler(nanniesController.getById))
router.put('/me',  requireAuth, requireRole('NANNY'), asyncHandler(nanniesController.updateMyProfile))

export default router
