import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { recurringBookingsController } from './recurring-bookings.controller'

const router = Router()
router.use(requireAuth)

router.post('/',              requireRole('PARENT', 'ADMIN'), asyncHandler(recurringBookingsController.create))
router.get('/',               asyncHandler(recurringBookingsController.list))
router.get('/:id',            asyncHandler(recurringBookingsController.getById))
router.put('/:id',            requireRole('PARENT', 'ADMIN'), asyncHandler(recurringBookingsController.update))
router.patch('/:id/status',   asyncHandler(recurringBookingsController.updateStatus))

export default router
