import { prisma } from '../../db'

export const adminDal = {
  getStats() {
    return Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { role: 'NANNY' } }),
      prisma.user.count({ where: { role: 'PARENT' } }),
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
        isActive: true, isVerified: true, createdAt: true, phone: true,
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
          },
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
