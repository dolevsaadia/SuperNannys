import { prisma } from '../../db'
import type { BookingStatus } from '@prisma/client'

const bookingListInclude = {
  parent: { select: { id: true, fullName: true, avatarUrl: true } },
  nanny: { select: { id: true, fullName: true, avatarUrl: true } },
  review: { select: { rating: true, comment: true } },
  recurringBooking: { select: { id: true, status: true } },
  _count: { select: { messages: true } },
} as const

const bookingDetailInclude = {
  parent: { select: { id: true, fullName: true, avatarUrl: true, phone: true, city: true, streetName: true, houseNumber: true, postalCode: true, latitude: true, longitude: true } },
  nanny: {
    select: {
      id: true, fullName: true, avatarUrl: true, phone: true,
      nannyProfile: {
        select: {
          hourlyRateNis: true, recurringHourlyRateNis: true, city: true, rating: true, badges: true,
          latitude: true, longitude: true, minimumHoursPerBooking: true, allowsBabysittingAtHome: true,
          streetName: true, houseNumber: true, postalCode: true,
        },
      },
    },
  },
  review: true,
  recurringBooking: { select: { id: true, status: true, daysOfWeek: true, startTime: true, endTime: true } },
  earning: { select: { netAmountNis: true, isPaid: true } },
} as const

export const bookingsDal = {
  findNannyProfile(nannyUserId: string) {
    return prisma.nannyProfile.findUnique({ where: { userId: nannyUserId } })
  },

  // INDEX HINT: This query benefits from a composite index on
  // Booking(nannyUserId, status, startTime, endTime) to avoid full scans
  // when checking for scheduling conflicts.
  findConflict(nannyUserId: string, start: Date, end: Date) {
    return prisma.booking.findFirst({
      where: {
        nannyUserId,
        status: { in: ['REQUESTED', 'ACCEPTED', 'IN_PROGRESS'] },
        startTime: { lt: end },
        endTime: { gt: start },
      },
    })
  },

  create(data: {
    parentUserId: string
    nannyUserId: string
    startTime: Date
    endTime: Date
    hourlyRateNis: number
    totalAmountNis: number
    estimatedPriceNis?: number
    notes?: string
    childrenCount: number
    childrenAges?: string[]
    address?: string
    isRecurring?: boolean
    recurringBookingId?: string
    occurrenceDate?: Date
    status?: BookingStatus
    // Structured address
    bookingCity?: string
    bookingStreet?: string
    bookingHouseNum?: string
    bookingPostalCode?: string
    bookingLat?: number
    bookingLng?: number
    locationType?: string
  }) {
    return prisma.booking.create({
      data,
      include: {
        parent: { select: { fullName: true, avatarUrl: true, phone: true } },
        nanny: { select: { fullName: true, avatarUrl: true, phone: true } },
      },
    })
  },

  // Check date availability blocks for conflict
  findDateBlock(nannyProfileId: string, date: Date, startTime: string, endTime: string) {
    return prisma.nannyDateAvailability.findFirst({
      where: {
        nannyProfileId,
        date: {
          gte: new Date(date.getFullYear(), date.getMonth(), date.getDate()),
          lt: new Date(date.getFullYear(), date.getMonth(), date.getDate() + 1),
        },
        isBlocked: true,
      },
    })
  },

  findMany(where: Record<string, unknown>, skip: number, take: number) {
    return prisma.booking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      include: bookingListInclude,
    })
  },

  count(where: Record<string, unknown>) {
    return prisma.booking.count({ where })
  },

  findById(id: string) {
    return prisma.booking.findUnique({ where: { id }, include: bookingDetailInclude })
  },

  findByIdSimple(id: string) {
    return prisma.booking.findUnique({ where: { id } })
  },

  updateStatus(id: string, status: BookingStatus) {
    return prisma.booking.update({ where: { id }, data: { status } })
  },

  upsertEarning(data: { nannyUserId: string; bookingId: string; amountNis: number; platformFee: number; netAmountNis: number }) {
    return prisma.earning.upsert({
      where: { bookingId: data.bookingId },
      update: {},
      create: data,
    })
  },

  updateNannyStats(nannyUserId: string, netAmount: number) {
    return prisma.nannyProfile.update({
      where: { userId: nannyUserId },
      data: {
        completedJobs: { increment: 1 },
        totalEarnings: { increment: netAmount },
      },
    })
  },
}
