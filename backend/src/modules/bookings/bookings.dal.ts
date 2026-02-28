import { prisma } from '../../db'
import type { BookingStatus } from '@prisma/client'

const bookingListInclude = {
  parent: { select: { id: true, fullName: true, avatarUrl: true } },
  nanny: { select: { id: true, fullName: true, avatarUrl: true } },
  review: { select: { rating: true, comment: true } },
  _count: { select: { messages: true } },
} as const

const bookingDetailInclude = {
  parent: { select: { id: true, fullName: true, avatarUrl: true, phone: true } },
  nanny: {
    select: {
      id: true, fullName: true, avatarUrl: true, phone: true,
      nannyProfile: { select: { hourlyRateNis: true, city: true, rating: true, badges: true, latitude: true, longitude: true } },
    },
  },
  review: true,
  earning: { select: { netAmountNis: true, isPaid: true } },
} as const

export const bookingsDal = {
  findNannyProfile(nannyUserId: string) {
    return prisma.nannyProfile.findUnique({ where: { userId: nannyUserId } })
  },

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
    notes?: string
    childrenCount: number
    childrenAges?: string[]
    address?: string
  }) {
    return prisma.booking.create({
      data,
      include: {
        parent: { select: { fullName: true, avatarUrl: true, phone: true } },
        nanny: { select: { fullName: true, avatarUrl: true, phone: true } },
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
