import { prisma } from '../../db'
import type { RecurringBookingStatus } from '@prisma/client'

const recurringInclude = {
  parent: { select: { id: true, fullName: true, avatarUrl: true, phone: true } },
  nanny: {
    select: {
      id: true, fullName: true, avatarUrl: true, phone: true,
      nannyProfile: {
        select: { hourlyRateNis: true, recurringHourlyRateNis: true, city: true, rating: true, badges: true },
      },
    },
  },
  _count: { select: { bookings: true } },
} as const

export const recurringBookingsDal = {
  create(data: {
    parentUserId: string
    nannyUserId: string
    daysOfWeek: number[]
    startTime: string
    endTime: string
    startDate: Date
    endDate?: Date | null
    hourlyRateNis: number
    childrenCount: number
    childrenAges?: string[]
    address?: string
    notes?: string
  }) {
    return prisma.recurringBooking.create({
      data,
      include: recurringInclude,
    })
  },

  findById(id: string) {
    return prisma.recurringBooking.findUnique({
      where: { id },
      include: {
        ...recurringInclude,
        bookings: {
          orderBy: { startTime: 'desc' },
          take: 10,
          select: {
            id: true,
            startTime: true,
            endTime: true,
            status: true,
            occurrenceDate: true,
            totalAmountNis: true,
          },
        },
      },
    })
  },

  findMany(where: Record<string, unknown>, skip: number, take: number) {
    return prisma.recurringBooking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
      include: recurringInclude,
    })
  },

  count(where: Record<string, unknown>) {
    return prisma.recurringBooking.count({ where })
  },

  updateStatus(id: string, status: RecurringBookingStatus) {
    return prisma.recurringBooking.update({
      where: { id },
      data: { status },
      include: recurringInclude,
    })
  },

  update(id: string, data: Record<string, unknown>) {
    return prisma.recurringBooking.update({
      where: { id },
      data,
      include: recurringInclude,
    })
  },

  updateLastGenerated(id: string, date: Date) {
    return prisma.recurringBooking.update({
      where: { id },
      data: { lastGeneratedAt: date },
    })
  },

  // Find all ACTIVE recurring bookings that need generation
  findActiveForGeneration() {
    return prisma.recurringBooking.findMany({
      where: { status: 'ACTIVE' },
      include: {
        nanny: {
          select: {
            nannyProfile: { select: { recurringHourlyRateNis: true, hourlyRateNis: true } },
          },
        },
      },
    })
  },

  findNannyProfile(nannyUserId: string) {
    return prisma.nannyProfile.findUnique({ where: { userId: nannyUserId } })
  },

  // Check if a booking occurrence already exists for this date
  findExistingOccurrence(recurringBookingId: string, occurrenceDate: Date) {
    return prisma.booking.findFirst({
      where: {
        recurringBookingId,
        occurrenceDate,
        status: { notIn: ['CANCELLED', 'DECLINED'] },
      },
    })
  },
}
