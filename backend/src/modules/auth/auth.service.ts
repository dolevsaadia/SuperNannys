import bcrypt from 'bcryptjs'
import { OAuth2Client } from 'google-auth-library'
import { config } from '../../config'
import { signToken, signRefreshToken, generateTokenPair, generateTokenPairWithExpiry, verifyRefreshToken } from '../../shared/utils/jwt'
import { AppError, NotFoundError, ConflictError, AuthenticationError, ForbiddenError, ServiceUnavailableError, BadRequestError } from '../../shared/errors/app-error'
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
    throw new ServiceUnavailableError('Failed to send verification email')
  }
}

/** Check if a nanny has completed onboarding (city must be set). */
async function getNannyOnboardingCompleted(userId: string, role: string): Promise<boolean> {
  if (role !== 'NANNY') return true
  const profile = await authDal.findNannyProfileCity(userId)
  return profile != null && profile.city !== ''
}

export const authService = {
  async register(data: RegisterInput) {
    const email = data.email.toLowerCase()
    const existing = await authDal.findUserByEmail(email)
    if (existing) throw new ConflictError('Email already in use')

    // Check phone uniqueness if provided
    if (data.phone) {
      const phoneExists = await authDal.findUserByPhone(data.phone)
      if (phoneExists) throw new ConflictError('This phone number is already registered to another account.')
    }

    const passwordHash = await bcrypt.hash(data.password, 12)
    const userData = {
      email,
      passwordHash,
      fullName: data.fullName,
      phone: data.phone,
      dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
      role: data.role,
      // Structured address
      city: data.city,
      streetName: data.streetName,
      houseNumber: data.houseNumber,
      postalCode: data.postalCode,
      apartmentFloor: data.apartmentFloor,
    }

    // Atomic: create user + nanny profile in a single transaction if NANNY role
    const user = data.role === 'NANNY'
      ? await authDal.createUserWithNannyProfile(userData)
      : await authDal.createUser(userData)

    logger.info('User registered', { userId: user.id, email, role: data.role })

    const tokens = generateTokenPairWithExpiry({ userId: user.id, email: user.email, role: user.role })
    // New nannies always need onboarding
    return { ...tokens, user: { ...user, nannyOnboardingCompleted: data.role !== 'NANNY' ? true : false } }
  },

  async login(data: LoginInput) {
    const email = data.email.toLowerCase()
    const user = await authDal.findUserByEmail(email)

    if (!user || !user.passwordHash) {
      logger.warn('Login failed', { email, reason: 'invalid_credentials' })
      throw new AuthenticationError('Invalid credentials')
    }
    if (!user.isActive) {
      logger.warn('Login failed', { email, reason: 'account_deactivated' })
      throw new ForbiddenError('Account deactivated')
    }

    const valid = await bcrypt.compare(data.password, user.passwordHash)
    if (!valid) {
      logger.warn('Login failed', { email, reason: 'invalid_credentials' })
      throw new AuthenticationError('Invalid credentials')
    }

    logger.info('User logged in', { userId: user.id, email })

    const nannyOnboardingCompleted = await getNannyOnboardingCompleted(user.id, user.role)
    const tokens = generateTokenPairWithExpiry({ userId: user.id, email: user.email, role: user.role })
    return {
      ...tokens,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
        nannyOnboardingCompleted,
      },
    }
  },

  async googleSignIn(data: GoogleSignInInput) {
    if (!config.google.isConfigured) {
      throw new ServiceUnavailableError('Google Sign-In is not configured. Set GOOGLE_CLIENT_ID in .env')
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
      throw new AuthenticationError('Invalid or expired Google token')
    }
    if (!payload?.email) throw new AuthenticationError('Invalid Google token')

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

      // Check phone uniqueness if provided
      if (data.phone) {
        const phoneExists = await authDal.findUserByPhone(data.phone)
        if (phoneExists) throw new ConflictError('This phone number is already registered to another account.')
      }

      const googleUserData = {
        email: payload.email,
        fullName: payload.name || payload.email,
        avatarUrl: payload.picture,
        role: data.role,
        authProvider: 'GOOGLE' as const,
        googleSub: payload.sub,
        isVerified: data.role !== 'NANNY',  // Nannies require admin verification
        phone: data.phone,
        dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
      }
      // Atomic: create user + nanny profile in a single transaction if NANNY role
      const created = data.role === 'NANNY'
        ? await authDal.createUserWithNannyProfile(googleUserData)
        : await authDal.createUser(googleUserData)

      logger.info('Google sign-in', { email: payload.email, isNewUser: true, userId: created.id })

      const newTokens = generateTokenPairWithExpiry({ userId: created.id, email: created.email, role: created.role })
      return {
        ...newTokens,
        isNewUser: true,
        user: {
          id: created.id, email: created.email, fullName: created.fullName,
          role: created.role, avatarUrl: created.avatarUrl, isVerified: created.isVerified,
          nannyOnboardingCompleted: data.role !== 'NANNY' ? true : false,
        },
      }
    }

    // Block deactivated / deleted users
    if (!user.isActive) {
      logger.warn('Google sign-in blocked', { email: payload.email, reason: 'account_deactivated' })
      throw new ForbiddenError('Account deactivated')
    }

    // Existing user — link Google sub if missing
    if (!user.googleSub) {
      user = await authDal.updateGoogleSub(user.id, payload.sub!)
    }

    logger.info('Google sign-in', { email: payload.email, isNewUser: false, userId: user.id })

    const nannyOnboardingCompleted = await getNannyOnboardingCompleted(user.id, user.role)
    // Google already verified the email, so sign in directly (no OTP needed).
    const existingTokens = generateTokenPairWithExpiry({ userId: user.id, email: user.email, role: user.role })
    return {
      ...existingTokens,
      isNewUser: false,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
        nannyOnboardingCompleted,
      },
    }
  },

  async verifyOTP(data: { email: string; code: string }) {
    const email = data.email.toLowerCase()
    const record = await verificationDal.findValidCode(email, data.code)
    if (!record) {
      throw new BadRequestError('Invalid or expired verification code')
    }

    await verificationDal.markUsed(record.id)

    const user = await authDal.findUserByEmail(email)
    if (!user) throw new NotFoundError('User')

    logger.info('OTP verified', { userId: user.id, email })

    const nannyOnboardingCompleted = await getNannyOnboardingCompleted(user.id, user.role)
    const tokens = generateTokenPairWithExpiry({ userId: user.id, email: user.email, role: user.role })
    return {
      ...tokens,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
        nannyOnboardingCompleted,
      },
    }
  },

  async resendOTP(email: string) {
    const normalizedEmail = email.toLowerCase()
    const user = await authDal.findUserByEmail(normalizedEmail)
    if (!user) throw new NotFoundError('User')

    await sendOTP(normalizedEmail, user.id)
    logger.info('OTP resent', { userId: user.id, email: normalizedEmail })
    return { message: 'Verification code sent' }
  },

  /**
   * Refresh access token using a valid refresh token.
   * Returns a new access token + new refresh token (rotation).
   */
  async refreshToken(refreshTokenStr: string) {
    let payload
    try {
      payload = verifyRefreshToken(refreshTokenStr)
    } catch (err) {
      logger.warn('Refresh token invalid', {
        error: err instanceof Error ? err.message : String(err),
      })
      throw new AuthenticationError('Invalid or expired refresh token')
    }

    // Verify user still exists and is active
    const user = await authDal.findUserWithProfile(payload.userId)
    if (!user) throw new NotFoundError('User')
    if (!user.isActive) throw new ForbiddenError('Account deactivated')

    logger.info('Token refreshed', { userId: user.id })

    const nannyOnboardingCompleted = await getNannyOnboardingCompleted(user.id, user.role)
    // Issue new token pair (refresh token rotation)
    const tokens = generateTokenPairWithExpiry({ userId: user.id, email: user.email, role: user.role })
    return {
      ...tokens,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
        nannyOnboardingCompleted,
      },
    }
  },

  // Note: req.user! non-null assertion in controllers is safe —
  // requireAuth middleware guarantees the user object is present.
  async getMe(userId: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new NotFoundError('User')
    // Derive onboarding status from profile data
    const nannyOnboardingCompleted = user.role !== 'NANNY' || (user.nannyProfile?.city ?? '') !== ''
    return { ...user, nannyOnboardingCompleted }
  },

  /**
   * Send a phone verification code.
   * Uses the existing OTP infra (code stored in VerificationCode table).
   * In production, replace email fallback with a real SMS provider (Twilio).
   */
  async sendPhoneCode(userId: string, phone: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new NotFoundError('User')

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
      throw new BadRequestError('Invalid or expired verification code')
    }

    await verificationDal.markUsed(record.id)

    // Update user's phone and mark as verified
    await authDal.updatePhone(userId, phone)
    logger.info('Phone verified', { userId, phone })
    return { message: 'Phone verified successfully' }
  },
}
