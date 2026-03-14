import { Router } from 'express'
import { favoritesController } from './favorites.controller'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { asyncHandler } from '../../shared/middlewares/async-handler'

const router = Router()

router.use(requireAuth)
router.post('/toggle', asyncHandler(favoritesController.toggle))
router.get('/', asyncHandler(favoritesController.list))
router.get('/check/:nannyUserId', asyncHandler(favoritesController.check))

export default router
