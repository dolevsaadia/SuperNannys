import { prisma } from '../../db'

export const nanniesDal = {
  searchProfiles(where: Record<string, unknown>, orderBy: Record<string, string>, skip: number, take: number) {
    return prisma.nannyProfile.findMany({
      where,
      orderBy,
      skip,
      take,
      include: {
        user: { select: { id: true, fullName: true, avatarUrl: true } },
        availability: { orderBy: { dayOfWeek: 'asc' } },
      },
    })
  },

  countProfiles(where: Record<string, unknown>) {
    return prisma.nannyProfile.count({ where })
  },

  findByUserId(userId: string) {
    return prisma.nannyProfile.findUnique({
      where: { userId },
      include: { availability: { orderBy: { dayOfWeek: 'asc' } }, documents: true },
    })
  },

  findById(id: string) {
    return prisma.nannyProfile.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, fullName: true, avatarUrl: true, createdAt: true } },
        availability: { orderBy: { dayOfWeek: 'asc' } },
        documents: { select: { type: true, verifiedAt: true } },
      },
    })
  },

  getReviewsForNanny(nannyUserId: string, take = 10) {
    return prisma.review.findMany({
      where: { revieweeUserId: nannyUserId },
      orderBy: { createdAt: 'desc' },
      take,
      include: { reviewer: { select: { fullName: true, avatarUrl: true } } },
    })
  },

  updateProfile(userId: string, data: Record<string, unknown>) {
    return prisma.nannyProfile.update({ where: { userId }, data })
  },

  upsertAvailability(nannyProfileId: string, slot: { dayOfWeek: number; fromTime: string; toTime: string; isAvailable: boolean }) {
    return prisma.availability.upsert({
      where: { nannyProfileId_dayOfWeek: { nannyProfileId, dayOfWeek: slot.dayOfWeek } },
      update: { fromTime: slot.fromTime, toTime: slot.toTime, isAvailable: slot.isAvailable },
      create: { nannyProfileId, ...slot },
    })
  },
}
