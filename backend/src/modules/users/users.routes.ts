import { Router } from 'express'
import multer from 'multer'
import path from 'path'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth } from '../../shared/middlewares/auth.middleware'
import { usersController } from './users.controller'
import { config } from '../../config'

const avatarStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, config.upload.uploadDir),
  filename: (_req, file, cb) => cb(null, `avatar-${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname)}`),
})
const avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp/
    const ext = allowed.test(path.extname(file.originalname).toLowerCase())
    const mime = allowed.test(file.mimetype)
    cb(null, ext && mime)
  },
})

const router = Router()
router.use(requireAuth)

router.delete('/me',                         asyncHandler(usersController.deleteAccount))
router.put('/me',                         asyncHandler(usersController.updateProfile))
router.post('/me/avatar',                 avatarUpload.single('avatar'), asyncHandler(usersController.uploadAvatar))
router.get('/me/notifications',           asyncHandler(usersController.getNotifications))
router.patch('/me/notifications/read-all', asyncHandler(usersController.markAllNotificationsRead))
router.post('/me/devices',                asyncHandler(usersController.registerDevice))
router.get('/me/earnings',                asyncHandler(usersController.getEarnings))

export default router
