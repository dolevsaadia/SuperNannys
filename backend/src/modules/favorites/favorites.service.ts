import { favoritesDal } from './favorites.dal'

export const favoritesService = {
  toggle: (userId: string, nannyUserId: string) => favoritesDal.toggle(userId, nannyUserId),
  list: (userId: string) => favoritesDal.list(userId),
  check: (userId: string, nannyUserId: string) => favoritesDal.check(userId, nannyUserId),
}
