import { prisma } from '../../db'

export const verificationRequestsDal = {
  create(data: {
    userId: string
    idCardUrl?: string
    idAppendixUrl?: string
    policeClearanceUrl?: string
  }) {
    return prisma.verificationRequest.create({ data })
  },

  findByUserId(userId: string) {
    return prisma.verificationRequest.findFirst({
      where: { userId },
      orderBy: { submittedAt: 'desc' },
    })
  },

  findAll(status?: string) {
    const where = status ? { status } : {}
    return prisma.verificationRequest.findMany({
      where,
      orderBy: { submittedAt: 'desc' },
      include: {
        user: { select: { id: true, fullName: true, avatarUrl: true, email: true } },
      },
    })
  },

  findById(id: string) {
    return prisma.verificationRequest.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, fullName: true, avatarUrl: true, email: true } },
      },
    })
  },

  updateStatus(id: string, data: { status: string; adminNotes?: string; reviewedBy?: string }) {
    return prisma.verificationRequest.update({
      where: { id },
      data: {
        ...data,
        reviewedAt: new Date(),
      },
    })
  },
}
