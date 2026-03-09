import { Resend } from 'resend'
import { logger } from '../utils/logger'

let resendClient: Resend | null = null

function getResend(): Resend | null {
  if (resendClient) return resendClient
  const key = process.env.RESEND_API_KEY
  if (!key) return null
  resendClient = new Resend(key)
  return resendClient
}

export const emailService = {
  async sendVerificationCode(email: string, code: string): Promise<void> {
    // Always log to console for debugging
    logger.info(`\n===== VERIFICATION CODE =====`)
    logger.info(`📧 Email: ${email}`)
    logger.info(`🔑 Code:  ${code}`)
    logger.info(`=============================\n`)

    const resend = getResend()
    if (!resend) {
      logger.warn('⚠️  RESEND_API_KEY not set — code only logged to console')
      return
    }

    try {
      await resend.emails.send({
        from: process.env.RESEND_FROM || 'SuperNanny <onboarding@resend.dev>',
        to: email,
        subject: 'SuperNanny — Verification Code',
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 420px; margin: 0 auto; padding: 32px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <div style="display: inline-block; width: 56px; height: 56px; background: linear-gradient(135deg, #7C3AED, #9D5CF8); border-radius: 16px; line-height: 56px; font-size: 28px;">👶</div>
            </div>
            <h2 style="text-align: center; color: #1a1a2e; font-size: 22px; margin-bottom: 8px;">Verify your email</h2>
            <p style="text-align: center; color: #6b7280; font-size: 14px; margin-bottom: 28px;">Enter the code below to complete sign-in to SuperNanny</p>
            <div style="background: #f5f3ff; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 24px;">
              <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #7C3AED;">${code}</span>
            </div>
            <p style="text-align: center; color: #9ca3af; font-size: 12px;">This code expires in 5 minutes.<br>If you didn't request this, you can safely ignore it.</p>
          </div>
        `,
      })
      logger.info(`✅ Verification email sent to ${email}`)
    } catch (err) {
      logger.error(`❌ Failed to send email to ${email}:`, err)
    }
  },
}
