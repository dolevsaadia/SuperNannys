import { Router } from 'express'
import rateLimit from 'express-rate-limit'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { authController } from './auth.controller'

const router = Router()

// ── Strict rate limits for sensitive auth endpoints ──────────
// Prevents OTP brute-force and SMS/email abuse.
const otpRateLimit = rateLimit({
  windowMs: 60 * 1000,  // 1 minute window
  max: 3,               // max 3 requests per minute
  standardHeaders: true,
  message: { success: false, message: 'Too many attempts. Please wait a moment and try again.' },
})

const loginRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minute window
  max: 10,                   // max 10 login attempts per 15 min
  standardHeaders: true,
  message: { success: false, message: 'Too many login attempts. Please try again later.' },
})

router.post('/register',    asyncHandler(authController.register))
router.post('/login',       loginRateLimit, asyncHandler(authController.login))
router.post('/google',      asyncHandler(authController.googleSignIn))
router.post('/verify-otp',  otpRateLimit, asyncHandler(authController.verifyOTP))
router.post('/resend-otp',  otpRateLimit, asyncHandler(authController.resendOTP))
router.post('/refresh',     asyncHandler(authController.refreshToken))
router.get('/me',           requireAuth, asyncHandler(authController.getMe))
router.post('/send-phone-code', requireAuth, otpRateLimit, asyncHandler(authController.sendPhoneCode))
router.post('/verify-phone',    requireAuth, otpRateLimit, asyncHandler(authController.verifyPhone))

export default router
