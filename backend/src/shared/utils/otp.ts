import crypto from 'crypto'

export function generateOTP(length = 6): string {
  const max = Math.pow(10, length)
  const min = Math.pow(10, length - 1)
  const num = crypto.randomInt(min, max)
  return num.toString()
}
