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

    const pageNum = Math.max(1, parseInt(filters.page || '1'))
    const limitNum = Math.min(100, parseInt(filters.limit || '20'))
    const skip = (pageNum - 1) * limitNum

    const [users, total] = await Promise.all([
      adminDal.searchUsers(where, skip, limitNum),
      adminDal.countUsers(where),
    ])

    return { users, pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) } }
  },

  async updateUser(userId: string, data: UpdateUserInput) {
    return adminDal.updateUser(userId, data)
  },

  async getPendingNannies(filters: { page?: string; limit?: string }) {
    const where = { role: 'NANNY' as const, isVerified: false, isActive: true }
    const pageNum = Math.max(1, parseInt(filters.page || '1'))
    const limitNum = Math.min(100, parseInt(filters.limit || '20'))
    const skip = (pageNum - 1) * limitNum

    const [nannies, total] = await Promise.all([
      adminDal.getPendingNannies(where, skip, limitNum),
      adminDal.countPendingNannies(where),
    ])

    return { nannies, pagination: { total, page: pageNum, limit: limitNum, totalPages: Math.ceil(total / limitNum) } }
  },

  async getBookings(filters: { status?: string; page?: string; limit?: string }) {
    const where: Record<string, unknown> = {}
    if (filters.status) where.status = filters.status

    const pageNum = Math.max(1, parseInt(filters.page || '1'))
    const limitNum = Math.min(100, parseInt(filters.limit || '20'))
    const skip = (pageNum - 1) * limitNum

    const [bookings, total] = await Promise.all([
      adminDal.getBookings(where, skip, limitNum),
      adminDal.countBookings(where),
    ])

    return { bookings, pagination: { total, page: pageNum, limit: limitNum } }
  },
}
