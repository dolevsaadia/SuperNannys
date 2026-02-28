import { usersDal } from './users.dal'
import type { UpdateProfileInput, RegisterDeviceInput } from './users.validation'
import type { PaginationParams } from '../../shared/utils/pagination'

export const usersService = {
  async updateProfile(userId: string, data: UpdateProfileInput) {
    return usersDal.updateUser(userId, data)
  },

  async getNotifications(userId: string, pagination: PaginationParams) {
    const [notifications, unreadCount] = await Promise.all([
      usersDal.getNotifications(userId, pagination.skip, pagination.limit),
      usersDal.countUnreadNotifications(userId),
    ])
    return { notifications, unreadCount, pagination: { page: pagination.page, limit: pagination.limit } }
  },

  async markAllNotificationsRead(userId: string) {
    await usersDal.markAllNotificationsRead(userId)
    return { message: 'All notifications marked as read' }
  },

  async registerDevice(userId: string, data: RegisterDeviceInput) {
    await usersDal.upsertDevice(userId, data)
    return { message: 'Device registered' }
  },

  async getEarnings(userId: string) {
    const earnings = await usersDal.getEarnings(userId)
    const totalEarned = earnings.reduce((s, e) => s + e.netAmountNis, 0)
    const totalPending = earnings.filter(e => !e.isPaid).reduce((s, e) => s + e.netAmountNis, 0)
    return { earnings, summary: { totalEarned, totalPending, totalJobs: earnings.length } }
  },
}
