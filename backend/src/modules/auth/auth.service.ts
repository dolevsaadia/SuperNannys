import bcrypt from 'bcryptjs'
import { OAuth2Client } from 'google-auth-library'
import { config } from '../../config'
import { signToken } from '../../shared/utils/jwt'
import { AppError } from '../../shared/errors/app-error'
import { authDal } from './auth.dal'
import type { RegisterInput, LoginInput, GoogleSignInInput } from './auth.validation'

let googleClient: OAuth2Client | null = null
function getGoogleClient(): OAuth2Client {
  if (!googleClient) {
    googleClient = new OAuth2Client(config.google.clientId)
  }
  return googleClient
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
      audience: config.google.clientId,
    })
    const payload = ticket.getPayload()
    if (!payload?.email) throw new AppError('Invalid Google token', 401)

    let user = await authDal.findByGoogleSubOrEmail(payload.sub!, payload.email)
    let isNewUser = false

    if (!user) {
      isNewUser = true
      const userRole = data.role || 'PARENT'
      const created = await authDal.createUser({
        email: payload.email,
        fullName: payload.name || payload.email,
        avatarUrl: payload.picture,
        role: userRole,
        authProvider: 'GOOGLE',
        googleSub: payload.sub,
        isVerified: true,
      })
      if (userRole === 'NANNY') {
        await authDal.createNannyProfile(created.id)
      }
      const token = signToken({ userId: created.id, email: created.email, role: created.role })
      return {
        token,
        user: {
          id: created.id, email: created.email, fullName: created.fullName,
          role: created.role, avatarUrl: created.avatarUrl, isVerified: created.isVerified,
        },
        isNewUser,
      }
    }

    if (!user.googleSub) {
      user = await authDal.updateGoogleSub(user.id, payload.sub!)
    }

    const token = signToken({ userId: user.id, email: user.email, role: user.role })
    return {
      token,
      user: {
        id: user.id, email: user.email, fullName: user.fullName,
        role: user.role, avatarUrl: user.avatarUrl, isVerified: user.isVerified,
      },
      isNewUser,
    }
  },

  async getMe(userId: string) {
    const user = await authDal.findUserWithProfile(userId)
    if (!user) throw new AppError('User not found', 404)
    return user
  },
}
