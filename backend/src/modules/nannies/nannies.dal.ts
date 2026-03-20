import { prisma } from '../../db'
import type { DocumentType } from '@prisma/client'

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
      where: { nannyProfileId_dayOfWeek_fromTime: { nannyProfileId, dayOfWeek: slot.dayOfWeek, fromTime: slot.fromTime } },
      update: { toTime: slot.toTime, isAvailable: slot.isAvailable },
      create: { nannyProfileId, ...slot },
    })
  },

  deleteAvailabilityForDay(nannyProfileId: string, dayOfWeek: number) {
    return prisma.availability.deleteMany({
      where: { nannyProfileId, dayOfWeek },
    })
  },

  /** Atomically replace all availability slots for a nanny profile */
  replaceAllAvailability(nannyProfileId: string, slots: { dayOfWeek: number; fromTime: string; toTime: string; isAvailable: boolean }[]) {
    return prisma.$transaction([
      prisma.availability.deleteMany({ where: { nannyProfileId } }),
      ...slots.map(slot =>
        prisma.availability.create({
          data: { nannyProfileId, ...slot },
        })
      ),
    ])
  },

  createDocument(nannyProfileId: string, type: DocumentType, url: string) {
    return prisma.document.create({
      data: { nannyProfileId, type, url },
    })
  },

  getDocuments(nannyProfileId: string) {
    return prisma.document.findMany({
      where: { nannyProfileId },
      orderBy: { createdAt: 'desc' },
    })
  },

  deleteDocument(nannyProfileId: string, docId: string) {
    return prisma.document.deleteMany({
      where: { id: docId, nannyProfileId },
    })
  },

  verifyDocument(docId: string) {
    return prisma.document.update({
      where: { id: docId },
      data: { verifiedAt: new Date() },
    })
  },

  // ── Date-specific availability ────────────────────────────
  createDateAvailability(nannyProfileId: string, data: { date: Date; startTime: string; endTime: string; isBlocked?: boolean }) {
    return prisma.nannyDateAvailability.create({
      data: { nannyProfileId, ...data },
    })
  },

  upsertDateAvailability(nannyProfileId: string, data: { date: Date; startTime: string; endTime: string; isBlocked?: boolean }) {
    return prisma.nannyDateAvailability.upsert({
      where: {
        nannyProfileId_date_startTime: { nannyProfileId, date: data.date, startTime: data.startTime },
      },
      update: { endTime: data.endTime, isBlocked: data.isBlocked ?? false },
      create: { nannyProfileId, ...data },
    })
  },

  getDateAvailability(nannyProfileId: string, startDate: Date, endDate: Date) {
    return prisma.nannyDateAvailability.findMany({
      where: {
        nannyProfileId,
        date: { gte: startDate, lte: endDate },
      },
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
    })
  },

  deleteDateAvailability(nannyProfileId: string, slotId: string) {
    return prisma.nannyDateAvailability.deleteMany({
      where: { id: slotId, nannyProfileId },
    })
  },

  blockDate(nannyProfileId: string, date: Date) {
    return prisma.nannyDateAvailability.create({
      data: { nannyProfileId, date, startTime: '00:00', endTime: '23:59', isBlocked: true },
    })
  },

  // ── Get bookings for a nanny in a date range (for calendar) ──
  getNannyBookingsForRange(nannyUserId: string, startDate: Date, endDate: Date) {
    return prisma.booking.findMany({
      where: {
        nannyUserId,
        status: { in: ['REQUESTED', 'ACCEPTED', 'IN_PROGRESS'] },
        startTime: { lt: endDate },
        endTime: { gt: startDate },
      },
      select: {
        id: true,
        startTime: true,
        endTime: true,
        status: true,
      },
      orderBy: { startTime: 'asc' },
    })
  },

  // ── Check date availability blocks for conflict ──
  findDateBlock(nannyProfileId: string, date: Date, startTime: string, endTime: string) {
    return prisma.nannyDateAvailability.findFirst({
      where: {
        nannyProfileId,
        date,
        isBlocked: true,
        // Check if the blocked slot overlaps the requested time
        startTime: { lte: endTime },
        endTime: { gte: startTime },
      },
    })
  },
}
