import jwt from 'jsonwebtoken'
import ms, { type StringValue } from 'ms'
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

/**
 * Generate token pair WITH expiry timestamps.
 * The client uses expiresAt to schedule proactive refresh
 * before the token actually expires — no more silent logouts.
 */
export function generateTokenPairWithExpiry(payload: JwtPayload) {
  const now = Date.now()
  const expiresInMs = ms(config.jwt.expiresIn as StringValue)
  const refreshExpiresInMs = ms(config.jwt.refreshExpiresIn as StringValue)

  return {
    token: signToken(payload),
    refreshToken: signRefreshToken(payload),
    expiresAt: now + expiresInMs,
    refreshExpiresAt: now + refreshExpiresInMs,
  }
}
