import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { sessionsController } from './sessions.controller'

const router = Router()
router.use(requireAuth)

router.post('/:bookingId/confirm-start', asyncHandler(sessionsController.confirmStart))
router.post('/:bookingId/request-end',   asyncHandler(sessionsController.requestEnd))
router.post('/:bookingId/confirm-end',   asyncHandler(sessionsController.confirmEnd))
router.get('/:bookingId/state',          asyncHandler(sessionsController.getState))
router.get('/active',                    asyncHandler(sessionsController.getActive))

export default router
