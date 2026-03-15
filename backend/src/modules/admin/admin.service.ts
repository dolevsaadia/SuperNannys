import { parsePagination, paginationMeta } from '../../shared/utils/pagination'
import { adminDal } from './admin.dal'
import type { UpdateUserInput } from './admin.validation'

export const adminService = {
  async getStats() {
    const [totalUsers, totalNannies, totalParents, totalBookings, pendingBookings, completedBookings, revenueAgg] =
      await adminDal.getStats()

    return {
      users: { total: totalUsers, nannies: totalNannies, parents: totalParents },
      bookings: { total: totalBookings, pending: pendingBookings, completed: completedBookings },
      revenue: {
        platformFees: revenueAgg._sum.platformFee || 0,
        grossVolume: revenueAgg._sum.amountNis || 0,
      },
    }
  },

  async getUsers(filters: { search?: string; role?: string; isActive?: string; page?: string; limit?: string }) {
    const where: Record<string, unknown> = {}
    if (filters.role) where.role = filters.role
    if (filters.isActive !== undefined) where.isActive = filters.isActive === 'true'
    if (filters.search) {
      where.OR = [
        { fullName: { contains: filters.search, mode: 'insensitive' } },
        { email: { contains: filters.search, mode: 'insensitive' } },
      ]
    }

    const { page, limit, skip } = parsePagination(filters, 100)

    const [users, total] = await Promise.all([
      adminDal.searchUsers(where, skip, limit),
      adminDal.countUsers(where),
    ])

    return { users, pagination: paginationMeta(total, page, limit) }
  },

  async updateUser(userId: string, data: UpdateUserInput) {
    return adminDal.updateUser(userId, data)
  },

  async getPendingNannies(filters: { page?: string; limit?: string }) {
    const where = { role: 'NANNY' as const, isVerified: false, isActive: true }
    const { page, limit, skip } = parsePagination(filters, 100)

    const [nannies, total] = await Promise.all([
      adminDal.getPendingNannies(where, skip, limit),
      adminDal.countPendingNannies(where),
    ])

    return { nannies, pagination: paginationMeta(total, page, limit) }
  },

  async getBookings(filters: { status?: string; page?: string; limit?: string }) {
    const where: Record<string, unknown> = {}
    if (filters.status) where.status = filters.status

    const { page, limit, skip } = parsePagination(filters, 100)

    const [bookings, total] = await Promise.all([
      adminDal.getBookings(where, skip, limit),
      adminDal.countBookings(where),
    ])

    return { bookings, pagination: paginationMeta(total, page, limit) }
  },
}
