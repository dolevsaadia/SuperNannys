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

  findByGoogleSubOrEmail(sub: string, email: string) {
    return prisma.user.findFirst({
      where: { OR: [{ googleSub: sub }, { email }] },
    })
  },

  createUser(data: Prisma.UserCreateInput) {
    return prisma.user.create({ data, select: userPublicSelect })
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

  findUserWithProfile(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true, email: true, fullName: true, phone: true, phoneVerified: true, role: true,
        avatarUrl: true, isVerified: true, createdAt: true,
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
