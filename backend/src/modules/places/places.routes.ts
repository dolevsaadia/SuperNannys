import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { placesController } from './places.controller'

const router = Router()

router.get('/autocomplete', asyncHandler(placesController.autocomplete))

export default router
