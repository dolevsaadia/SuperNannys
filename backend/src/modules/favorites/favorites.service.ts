import { AppError, ValidationError } from '../../shared/errors/app-error'
import { favoritesDal } from './favorites.dal'

export const favoritesService = {
  toggle: (userId: string, nannyUserId: string) => {
    if (!nannyUserId) throw new ValidationError('nannyUserId is required')
    return favoritesDal.toggle(userId, nannyUserId)
  },
  list: (userId: string) => favoritesDal.list(userId),
  check: (userId: string, nannyUserId: string) => favoritesDal.check(userId, nannyUserId),
}
