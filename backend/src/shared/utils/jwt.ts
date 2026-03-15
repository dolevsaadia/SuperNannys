import jwt from 'jsonwebtoken'
import { config } from '../../config'

export interface JwtPayload {
  userId: string
  email: string
  role: string
}

/** Short-lived access token (default 1h) */
export function signToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  } as jwt.SignOptions)
}

/** Long-lived refresh token (default 30d) */
export function signRefreshToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn,
  } as jwt.SignOptions)
}

/** Verify an access token */
export function verifyToken(token: string): JwtPayload {
  return jwt.verify(token, config.jwt.secret) as JwtPayload
}

/** Verify a refresh token */
export function verifyRefreshToken(token: string): JwtPayload {
  return jwt.verify(token, config.jwt.refreshSecret) as JwtPayload
}

/** Generate both tokens at once (convenience helper) */
export function generateTokenPair(payload: JwtPayload) {
  return {
    token: signToken(payload),
    refreshToken: signRefreshToken(payload),
  }
}
