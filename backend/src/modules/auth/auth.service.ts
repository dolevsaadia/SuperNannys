import bcrypt from 'bcryptjs'
import { OAuth2Client } from 'google-auth-library'
import { config } from '../../config'
import { signToken } from '../../shared/utils/jwt'
import { AppError } from '../../shared/errors/app-error'
import { generateOTP } from '../../shared/utils/otp'
import { emailService } from '../../shared/services/email.service'
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
  await emailService.sendVerificationCode(email, code)
}

export const authService = {
  async register(data: RegisterInput) {
    const existing = await authDal.findUserByEmail(data.email)
    if (existing) throw new AppError('Email already in use', 409)

    const passwordHash = await bcrypt.hash(data.password, 12)
    const user = await authDal.createUser({
      email: data.email,
      passwordHash,
      fullName: data.fullName,
      phone: data.phone,
      role: data.role,
    })

    if (data.role === 'NANNY') {
      await authDal.createNannyProfile(user.id)
    }

    const token = signToken({ userId: user.id, email: user.email, role: user.role })
    return { token, user }
  },

  async login(data: LoginInput) {
    const user = await authDal.findUserByEmail(data.email)
    if (!user || !user.passwordHash) throw new AppError('Invalid credentials', 401)
    if (!user.isActive) throw new AppError('Account deactivated', 403)

    const valid = await bcrypt.compare(data.password, user.passwordHash)
    if (!valid) throw new AppError('Invalid credentials', 401)

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
    const ticket = await client.verifyIdToken({
      idToken: data.idToken,
      audience: config.google.allClientIds,
    })
    const payload = ticket.getPayload()
    if (!payload?.email) throw new AppError('Invalid Google token', 401)

    let user = await authDal.findByGoogleSubOrEmail(payload.sub!, payload.email)
    let isNewUser = false

    if (!user) {
      if (!data.role) {
        // New user — don't create yet, let client ask for role first
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

      // New user with role — create account then send OTP
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

      await sendOTP(payload.email, created.id)
      return {
        pendingVerification: true,
        email: payload.email,
        isNewUser: true,
      }
    }

    // Existing user — link Google sub if missing
    if (!user.googleSub) {
      user = await authDal.updateGoogleSub(user.id, payload.sub!)
    }

    // Send OTP for existing users
    await sendOTP(user.email, user.id)
    return {
      pendingVerification: true,
      email: user.email,
      isNewUser: false,
    }
  },

  async verifyOTP(data: { email: string; code: string }) {
    const record = await verificationDal.findValidCode(data.email, data.code)
    if (!record) {
      throw new AppError('Invalid or expired verification code', 400)
    }

    await verificationDal.markUsed(record.id)

    const user = await authDal.findUserByEmail(data.email)
    if (!user) throw new AppError('User not found', 404)

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
    const user = await authDal.findUserByEmail(email)
    if (!user) throw new AppError('User not found', 404)

    await sendOTP(email, user.id)
    return { message: 'Verification code sent' }
  },

  async getMe(userId: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new AppError('User not found', 404)
    return user
  },
}
