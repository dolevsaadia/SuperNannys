import { prisma } from '../../db'
import { Prisma } from '@prisma/client'

const userPublicSelect = {
  id: true,
  email: true,
  fullName: true,
  role: true,
  avatarUrl: true,
  isVerified: true,
  phone: true,
  phoneVerified: true,
  city: true,
  streetName: true,
  houseNumber: true,
  postalCode: true,
  apartmentFloor: true,
  latitude: true,
  longitude: true,
} satisfies Prisma.UserSelect

export const authDal = {
  findUserByEmail(email: string) {
    return prisma.user.findUnique({ where: { email } })
  },

  findUserByPhone(phone: string) {
    return prisma.user.findUnique({ where: { phone } })
  },

  findByGoogleSubOrEmail(sub: string, email: string) {
    return prisma.user.findFirst({
      where: { OR: [{ googleSub: sub }, { email }] },
    })
  },

  createUser(data: Prisma.UserCreateInput) {
    return prisma.user.create({ data, select: userPublicSelect })
  },

  /** Create user + nanny profile atomically in a single transaction */
  createUserWithNannyProfile(data: Prisma.UserCreateInput) {
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.create({ data, select: userPublicSelect })
      await tx.nannyProfile.create({ data: { userId: user.id } })
      return user
    })
  },

  createNannyProfile(userId: string) {
    return prisma.nannyProfile.create({ data: { userId } })
  },

  updateGoogleSub(userId: string, sub: string) {
    return prisma.user.update({
      where: { id: userId },
      data: { googleSub: sub, authProvider: 'GOOGLE' },
    })
  },

  updatePhone(userId: string, phone: string) {
    return prisma.user.update({
      where: { id: userId },
      data: { phone, phoneVerified: true },
    })
  },

  findNannyProfileCity(userId: string) {
    return prisma.nannyProfile.findUnique({
      where: { userId },
      select: { city: true },
    })
  },

  findUserWithProfile(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true, email: true, fullName: true, phone: true, phoneVerified: true, role: true,
        avatarUrl: true, isVerified: true, isActive: true, createdAt: true,
        city: true, streetName: true, houseNumber: true, postalCode: true, apartmentFloor: true,
        latitude: true, longitude: true, isOnline: true, lastSeenAt: true,
        nannyProfile: {
          select: {
            id: true, headline: true, hourlyRateNis: true, recurringHourlyRateNis: true,
            rating: true, reviewsCount: true,
            isVerified: true, isAvailable: true, city: true, badges: true,
            completedJobs: true, totalEarnings: true,
            minimumHoursPerBooking: true, allowsBabysittingAtHome: true,
            streetName: true, houseNumber: true, postalCode: true, apartmentFloor: true,
          },
        },
      },
    })
  },
}
