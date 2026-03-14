import bcrypt from 'bcryptjs'
import { OAuth2Client } from 'google-auth-library'
import { config } from '../../config'
import { signToken } from '../../shared/utils/jwt'
import { AppError } from '../../shared/errors/app-error'
import { generateOTP } from '../../shared/utils/otp'
import { emailService } from '../../shared/services/email.service'
import { logger } from '../../shared/utils/logger'
import { authDal } from './auth.dal'
import { verificationDal } from './verification.dal'
import type { RegisterInput, LoginInput, GoogleSignInInput } from './auth.validation'

let googleClient: OAuth2Client | null = null
function getGoogleClient(): OAuth2Client {
  if (!googleClient) {
    googleClient = new OAuth2Client(config.google.clientId)
  }
  return googleClient
}

/** Generate and send an OTP for a given email */
async function sendOTP(email: string, userId?: string) {
  await verificationDal.invalidateExisting(email)
  const code = generateOTP()
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
  await verificationDal.createCode({ email, code, userId, expiresAt })

  try {
    await emailService.sendVerificationCode(email, code)
  } catch (err) {
    logger.error('Failed to send OTP email', {
      email,
      userId,
      error: err instanceof Error ? err.message : String(err),
    })
    throw new AppError('Failed to send verification email', 500)
  }
}

export const authService = {
  async register(data: RegisterInput) {
    const email = data.email.toLowerCase()
    const existing = await authDal.findUserByEmail(email)
    if (existing) throw new AppError('Email already in use', 409)

    const passwordHash = await bcrypt.hash(data.password, 12)
    const user = await authDal.createUser({
      email,
      passwordHash,
      fullName: data.fullName,
      phone: data.phone,
      idNumber: data.idNumber,
      role: data.role,
      // Structured address
      city: data.city,
      streetName: data.streetName,
      houseNumber: data.houseNumber,
      postalCode: data.postalCode,
      apartmentFloor: data.apartmentFloor,
    })

    if (data.role === 'NANNY') {
      await authDal.createNannyProfile(user.id)
    }

    logger.info('User registered', { userId: user.id, email, role: data.role })

    const token = signToken({ userId: user.id, email: user.email, role: user.role })
    return { token, user }
  },

  async login(data: LoginInput) {
    const email = data.email.toLowerCase()
    const user = await authDal.findUserByEmail(email)

    if (!user || !user.passwordHash) {
      logger.warn('Login failed', { email, reason: 'invalid_credentials' })
      throw new AppError('Invalid credentials', 401)
    }
    if (!user.isActive) {
      logger.warn('Login failed', { email, reason: 'account_deactivated' })
      throw new AppError('Account deactivated', 403)
    }

    const valid = await bcrypt.compare(data.password, user.passwordHash)
    if (!valid) {
      logger.warn('Login failed', { email, reason: 'invalid_credentials' })
      throw new AppError('Invalid credentials', 401)
    }

    logger.info('User logged in', { userId: user.id, email })

    const token = signToken({ userId: user.id, email: user.email, role: user.role })
    return {
      token,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
      },
    }
  },

  async googleSignIn(data: GoogleSignInInput) {
    if (!config.google.isConfigured) {
      throw new AppError(
        'Google Sign-In is not configured. Set GOOGLE_CLIENT_ID in .env',
        503,
      )
    }

    const client = getGoogleClient()
    let payload: import('google-auth-library').TokenPayload | undefined
    try {
      const ticket = await client.verifyIdToken({
        idToken: data.idToken,
        audience: config.google.allClientIds,
      })
      payload = ticket.getPayload()
    } catch (err) {
      logger.warn('Google token verification failed', {
        error: err instanceof Error ? err.message : String(err),
      })
      throw new AppError('Invalid or expired Google token', 401)
    }
    if (!payload?.email) throw new AppError('Invalid Google token', 401)

    let user = await authDal.findByGoogleSubOrEmail(payload.sub!, payload.email)
    let isNewUser = false

    if (!user) {
      if (!data.role) {
        // New user — don't create yet, let client ask for role first
        logger.info('Google sign-in: new user pending role selection', { email: payload.email })
        return {
          isNewUser: true,
          token: null,
          user: {
            email: payload.email,
            fullName: payload.name || payload.email,
            avatarUrl: payload.picture || null,
          },
        }
      }

      // New user with role — create account.
      // Google already verified the email, so sign in directly (no OTP needed).
      isNewUser = true
      const created = await authDal.createUser({
        email: payload.email,
        fullName: payload.name || payload.email,
        avatarUrl: payload.picture,
        role: data.role,
        authProvider: 'GOOGLE',
        googleSub: payload.sub,
        isVerified: true,
      })
      if (data.role === 'NANNY') {
        await authDal.createNannyProfile(created.id)
      }

      logger.info('Google sign-in', { email: payload.email, isNewUser: true, userId: created.id })

      const newToken = signToken({ userId: created.id, email: created.email, role: created.role })
      return {
        token: newToken,
        isNewUser: true,
        user: {
          id: created.id, email: created.email, fullName: created.fullName,
          role: created.role, avatarUrl: created.avatarUrl, isVerified: created.isVerified,
        },
      }
    }

    // Existing user — link Google sub if missing
    if (!user.googleSub) {
      user = await authDal.updateGoogleSub(user.id, payload.sub!)
    }

    logger.info('Google sign-in', { email: payload.email, isNewUser: false, userId: user.id })

    // Google already verified the email, so sign in directly (no OTP needed).
    const existingToken = signToken({ userId: user.id, email: user.email, role: user.role })
    return {
      token: existingToken,
      isNewUser: false,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
      },
    }
  },

  async verifyOTP(data: { email: string; code: string }) {
    const email = data.email.toLowerCase()
    const record = await verificationDal.findValidCode(email, data.code)
    if (!record) {
      throw new AppError('Invalid or expired verification code', 400)
    }

    await verificationDal.markUsed(record.id)

    const user = await authDal.findUserByEmail(email)
    if (!user) throw new AppError('User not found', 404)

    logger.info('OTP verified', { userId: user.id, email })

    const token = signToken({ userId: user.id, email: user.email, role: user.role })
    return {
      token,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
      },
    }
  },

  async resendOTP(email: string) {
    const normalizedEmail = email.toLowerCase()
    const user = await authDal.findUserByEmail(normalizedEmail)
    if (!user) throw new AppError('User not found', 404)

    await sendOTP(normalizedEmail, user.id)
    logger.info('OTP resent', { userId: user.id, email: normalizedEmail })
    return { message: 'Verification code sent' }
  },

  // Note: req.user! non-null assertion in controllers is safe —
  // requireAuth middleware guarantees the user object is present.
  async getMe(userId: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new AppError('User not found', 404)
    return user
  },

  /**
   * Send a phone verification code.
   * Uses the existing OTP infra (code stored in VerificationCode table).
   * In production, replace email fallback with a real SMS provider (Twilio).
   */
  async sendPhoneCode(userId: string, phone: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new AppError('User not found', 404)

    // Invalidate any existing phone codes
    await verificationDal.invalidateExisting(`phone:${phone}`)
    const code = generateOTP()
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000)
    await verificationDal.createCode({
      email: `phone:${phone}`,
      code,
      userId,
      expiresAt,
    })

    // Send via email as SMS fallback + log to console
    await emailService.sendPhoneVerificationCode(phone, code, user.email)
    logger.info('Phone verification code sent', { userId, phone })
    return { message: 'Verification code sent' }
  },

  /**
   * Verify phone code and mark user's phone as verified.
   */
  async verifyPhone(userId: string, phone: string, code: string) {
    const record = await verificationDal.findValidCode(`phone:${phone}`, code)
    if (!record) {
      throw new AppError('Invalid or expired verification code', 400)
    }

    await verificationDal.markUsed(record.id)

    // Update user's phone and mark as verified
    await authDal.updatePhone(userId, phone)
    logger.info('Phone verified', { userId, phone })
    return { message: 'Phone verified successfully' }
  },
}
