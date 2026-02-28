import { Router } from 'express'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { authController } from './auth.controller'

const router = Router()

router.post('/register', asyncHandler(authController.register))
router.post('/login',    asyncHandler(authController.login))
router.post('/google',   asyncHandler(authController.googleSignIn))
router.get('/me',        requireAuth, asyncHandler(authController.getMe))

export default router
