import { prisma } from '../../db'

export const adminDal = {
  getStats() {
    return Promise.all([
      prisma.user.count({ where: { isActive: true } }),
      prisma.user.count({ where: { role: 'NANNY', isActive: true } }),
      prisma.user.count({ where: { role: 'PARENT', isActive: true } }),
      prisma.booking.count(),
      prisma.booking.count({ where: { status: 'REQUESTED' } }),
      prisma.booking.count({ where: { status: 'COMPLETED' } }),
      prisma.earning.aggregate({ _sum: { platformFee: true, amountNis: true } }),
    ])
  },

  searchUsers(where: Record<string, unknown>, skip: number, take: number) {
    return prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      select: {
        id: true, email: true, fullName: true, role: true,
        isActive: true, isVerified: true, deletedAt: true, createdAt: true, phone: true,
        _count: { select: { parentBookings: true, nannyBookings: true } },
      },
    })
  },

  countUsers(where: Record<string, unknown>) {
    return prisma.user.count({ where })
  },

  updateUser(userId: string, data: Record<string, unknown>) {
    return prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, email: true, fullName: true, role: true, isActive: true, isVerified: true },
    })
  },

  getPendingNannies(where: Record<string, unknown>, skip: number, take: number) {
    return prisma.user.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      select: {
        id: true, email: true, fullName: true, phone: true,
        isVerified: true, createdAt: true, avatarUrl: true,
        nannyProfile: {
          select: {
            headline: true, hourlyRateNis: true, city: true,
            yearsExperience: true, languages: true, skills: true,
            completedJobs: true, rating: true, reviewsCount: true,
            documents: {
              select: { id: true, type: true, url: true, verifiedAt: true, createdAt: true },
              orderBy: { createdAt: 'desc' as const },
            },
          },
        },
        idNumber: true,
        verificationRequests: {
          select: {
            id: true, status: true,
            idCardUrl: true, idAppendixUrl: true, policeClearanceUrl: true,
            adminNotes: true, submittedAt: true, reviewedAt: true,
          },
          orderBy: { submittedAt: 'desc' as const },
          take: 1,
        },
      },
    })
  },

  countPendingNannies(where: Record<string, unknown>) {
    return prisma.user.count({ where })
  },

  getBookings(where: Record<string, unknown>, skip: number, take: number) {
    return prisma.booking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      include: {
        parent: { select: { fullName: true, email: true } },
        nanny: { select: { fullName: true, email: true } },
      },
    })
  },

  countBookings(where: Record<string, unknown>) {
    return prisma.booking.count({ where })
  },
}
