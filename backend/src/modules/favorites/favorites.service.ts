import { AppError } from '../../shared/errors/app-error'
import { favoritesDal } from './favorites.dal'

export const favoritesService = {
  toggle: (userId: string, nannyUserId: string) => {
    if (!nannyUserId) throw new AppError('nannyUserId is required', 400)
    return favoritesDal.toggle(userId, nannyUserId)
  },
  list: (userId: string) => favoritesDal.list(userId),
  check: (userId: string, nannyUserId: string) => favoritesDal.check(userId, nannyUserId),
}
