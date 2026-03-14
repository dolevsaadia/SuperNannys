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
  /**
   * Send a 6-digit verification code to the given email.
   * Always logs the code to console for dev convenience.
   * Throws on failure so the caller knows the email was not sent.
   */
  async sendVerificationCode(email: string, code: string): Promise<void> {
    logger.info('Verification code generated', { email, code })

    const resend = getResend()
    if (!resend) {
      logger.warn('RESEND_API_KEY not set — code only logged to console', { email })
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
      logger.info('Verification email sent', { email })
    } catch (err: any) {
      logger.error('Failed to send verification email', { email, error: err.message })
      // Re-throw so callers can handle or report the failure
      throw err
    }
  },

  /**
   * Send a chat message notification email to the recipient.
   * Non-blocking: failures are logged but don't throw.
   */
  async sendChatNotification(
    recipientEmail: string,
    senderName: string,
    messagePreview: string,
    bookingId: string,
  ): Promise<void> {
    const resend = getResend()
    if (!resend) return

    const preview = messagePreview.length > 100 ? messagePreview.slice(0, 100) + '…' : messagePreview

    try {
      await resend.emails.send({
        from: process.env.RESEND_FROM || 'SuperNanny <onboarding@resend.dev>',
        to: recipientEmail,
        subject: `SuperNanny — New message from ${senderName}`,
        html: `
          <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 420px; margin: 0 auto; padding: 32px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <div style="display: inline-block; width: 56px; height: 56px; background: linear-gradient(135deg, #7C3AED, #9D5CF8); border-radius: 16px; line-height: 56px; font-size: 28px;">💬</div>
            </div>
            <h2 style="text-align: center; color: #1a1a2e; font-size: 22px; margin-bottom: 8px;">New Message</h2>
            <p style="text-align: center; color: #6b7280; font-size: 14px; margin-bottom: 20px;"><strong>${senderName}</strong> sent you a message</p>
            <div style="background: #f5f3ff; border-radius: 12px; padding: 16px; margin-bottom: 24px;">
              <p style="color: #374151; font-size: 14px; margin: 0; line-height: 1.5;">"${preview}"</p>
            </div>
            <div style="text-align: center;">
              <a href="supernanny://chat/${bookingId}" style="display: inline-block; background: linear-gradient(135deg, #7C3AED, #9D5CF8); color: white; padding: 12px 28px; border-radius: 12px; text-decoration: none; font-weight: 600; font-size: 14px;">Open Chat</a>
            </div>
            <p style="text-align: center; color: #9ca3af; font-size: 11px; margin-top: 20px;">You're receiving this because someone sent you a message on SuperNanny.</p>
          </div>
        `,
      })
      logger.info('Chat notification email sent', { recipientEmail, senderName, bookingId })
    } catch (err: any) {
      logger.error('Failed to send chat notification email', { recipientEmail, error: err.message })
    }
  },

  /**
   * Send a phone verification code via email (SMS placeholder).
   * In production, replace this with a real SMS provider (Twilio, etc.).
   * For now, sends the code via email as a fallback, and logs to console.
   */
  async sendPhoneVerificationCode(phone: string, code: string, email?: string): Promise<void> {
    logger.info('Phone verification code generated', { phone, code })

    // If we have an email, send the code there too (as SMS fallback)
    if (email) {
      const resend = getResend()
      if (resend) {
        try {
          await resend.emails.send({
            from: process.env.RESEND_FROM || 'SuperNanny <onboarding@resend.dev>',
            to: email,
            subject: 'SuperNanny — Phone Verification Code',
            html: `
              <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 420px; margin: 0 auto; padding: 32px;">
                <div style="text-align: center; margin-bottom: 24px;">
                  <div style="display: inline-block; width: 56px; height: 56px; background: linear-gradient(135deg, #7C3AED, #9D5CF8); border-radius: 16px; line-height: 56px; font-size: 28px;">📱</div>
                </div>
                <h2 style="text-align: center; color: #1a1a2e; font-size: 22px; margin-bottom: 8px;">Verify your phone</h2>
                <p style="text-align: center; color: #6b7280; font-size: 14px; margin-bottom: 28px;">Your phone verification code for ${phone}</p>
                <div style="background: #f5f3ff; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 24px;">
                  <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #7C3AED;">${code}</span>
                </div>
                <p style="text-align: center; color: #9ca3af; font-size: 12px;">This code expires in 5 minutes.</p>
              </div>
            `,
          })
        } catch (err: any) {
          logger.error('Failed to send phone verification email', { phone, error: err.message })
        }
      }
    }
  },
}
