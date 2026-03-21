import { prisma } from '../../db'

const sessionInclude = {
  parent: { select: { id: true, fullName: true, avatarUrl: true, phone: true } },
  nanny: {
    select: {
      id: true, fullName: true, avatarUrl: true, phone: true,
      nannyProfile: { select: { hourlyRateNis: true, city: true, minimumHoursPerBooking: true, allowsBabysittingAtHome: true } },
    },
  },
} as const

export const sessionsDal = {
  findBookingById(id: string) {
    return prisma.booking.findUnique({ where: { id }, include: sessionInclude })
  },

  findBookingByIdSimple(id: string) {
    return prisma.booking.findUnique({ where: { id } })
  },

  /** Mark parent's start confirmation */
  confirmParentStart(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: { parentConfirmedStart: true },
      include: sessionInclude,
    })
  },

  /** Mark nanny's start confirmation */
  confirmNannyStart(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: { nannyConfirmedStart: true },
      include: sessionInclude,
    })
  },

  /** Both confirmed — start the session */
  startSession(bookingId: string, actualStartTime: Date) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'IN_PROGRESS',
        actualStartTime,
      },
      include: sessionInclude,
    })
  },

  /** Mark parent's end confirmation */
  confirmParentEnd(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: { parentConfirmedEnd: true },
      include: sessionInclude,
    })
  },

  /** Mark nanny's end confirmation */
  confirmNannyEnd(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: { nannyConfirmedEnd: true },
      include: sessionInclude,
    })
  },

  /** Both confirmed end — complete the session */
  completeSession(bookingId: string, data: {
    actualEndTime: Date
    actualDurationMin: number
    finalAmountNis: number
    overtimeAmountNis: number
  }) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'COMPLETED',
        actualEndTime: data.actualEndTime,
        actualDurationMin: data.actualDurationMin,
        finalAmountNis: data.finalAmountNis,
        overtimeAmountNis: data.overtimeAmountNis,
      },
      include: sessionInclude,
    })
  },

  /** Create earning record after session */
  upsertEarning(data: {
    nannyUserId: string
    bookingId: string
    amountNis: number
    platformFee: number
    netAmountNis: number
  }) {
    return prisma.earning.upsert({
      where: { bookingId: data.bookingId },
      update: {
        amountNis: data.amountNis,
        platformFee: data.platformFee,
        netAmountNis: data.netAmountNis,
      },
      create: data,
    })
  },

  /** Update nanny stats after session */
  updateNannyStats(nannyUserId: string, netAmount: number) {
    return prisma.nannyProfile.update({
      where: { userId: nannyUserId },
      data: {
        completedJobs: { increment: 1 },
        totalEarnings: { increment: netAmount },
      },
    })
  },

  /** Find active IN_PROGRESS booking for a user */
  findActiveSession(userId: string) {
    return prisma.booking.findFirst({
      where: {
        status: 'IN_PROGRESS',
        OR: [{ parentUserId: userId }, { nannyUserId: userId }],
      },
      include: sessionInclude,
    })
  },

  /** Find all IN_PROGRESS bookings (for server restart recovery) */
  findAllActiveSessions() {
    return prisma.booking.findMany({
      where: { status: 'IN_PROGRESS' },
      include: sessionInclude,
    })
  },

  /** Cancel booking (auto-timeout) */
  cancelBooking(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'CANCELLED' },
    })
  },

  /** Reset start confirmations (for cancel during confirmation phase) */
  resetStartConfirmations(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: {
        parentConfirmedStart: false,
        nannyConfirmedStart: false,
      },
      include: sessionInclude,
    })
  },

  /** Cancel an active session — sets status back to ACCEPTED, resets all flags */
  cancelActiveSession(bookingId: string) {
    return prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'ACCEPTED',
        parentConfirmedStart: false,
        nannyConfirmedStart: false,
        parentConfirmedEnd: false,
        nannyConfirmedEnd: false,
        actualStartTime: null,
        actualEndTime: null,
        actualDurationMin: null,
        finalAmountNis: null,
        overtimeAmountNis: 0,
      },
      include: sessionInclude,
    })
  },
}
