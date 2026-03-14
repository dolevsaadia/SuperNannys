import { prisma } from '../../db'

export const favoritesDal = {
  async toggle(userId: string, nannyUserId: string) {
    const existing = await prisma.favorite.findUnique({
      where: { userId_nannyUserId: { userId, nannyUserId } },
    })
    if (existing) {
      await prisma.favorite.delete({ where: { id: existing.id } })
      return { isFavorited: false }
    }
    await prisma.favorite.create({ data: { userId, nannyUserId } })
    return { isFavorited: true }
  },

  async list(userId: string) {
    return prisma.favorite.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        nannyUser: {
          select: {
            id: true,
            fullName: true,
            avatarUrl: true,
            nannyProfile: {
              select: {
                hourlyRateNis: true,
                recurringHourlyRateNis: true,
                rating: true,
                reviewsCount: true,
                yearsExperience: true,
                headline: true,
                latitude: true,
                longitude: true,
                city: true,
              },
            },
          },
        },
      },
    })
  },

  async check(userId: string, nannyUserId: string) {
    const fav = await prisma.favorite.findUnique({
      where: { userId_nannyUserId: { userId, nannyUserId } },
    })
    return { isFavorited: !!fav }
  },
}
