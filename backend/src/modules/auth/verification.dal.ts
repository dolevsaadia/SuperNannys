import { prisma } from '../../db'

export const verificationDal = {
  createCode(data: { email: string; code: string; userId?: string; expiresAt: Date }) {
    return prisma.verificationCode.create({ data })
  },

  findValidCode(email: string, code: string) {
    return prisma.verificationCode.findFirst({
      where: {
        email,
        code,
        used: false,
        attempts: { lt: 5 },
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    })
  },

  markUsed(id: string) {
    return prisma.verificationCode.update({
      where: { id },
      data: { used: true },
    })
  },

  incrementAttempts(id: string) {
    return prisma.verificationCode.update({
      where: { id },
      data: { attempts: { increment: 1 } },
    })
  },

  /** Invalidate all unused codes for an email (when sending a new one) */
  invalidateExisting(email: string) {
    return prisma.verificationCode.updateMany({
      where: { email, used: false },
      data: { used: true },
    })
  },
}
