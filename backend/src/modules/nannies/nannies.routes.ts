import { Router } from 'express'
import multer from 'multer'
import path from 'path'
import { asyncHandler } from '../../shared/middlewares/async-handler'
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware'
import { nanniesController } from './nannies.controller'
import { config } from '../../config'

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, config.upload.uploadDir),
  filename: (_req, file, cb) => cb(null, `doc-${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname)}`),
})
const upload = multer({
  storage,
  limits: { fileSize: config.upload.maxFileSizeMb * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /jpeg|jpg|png|pdf|webp/
    const ext = allowed.test(path.extname(file.originalname).toLowerCase())
    const mime = allowed.test(file.mimetype)
    cb(null, ext && mime)
  },
})

const router = Router()

router.get('/',    asyncHandler(nanniesController.search))
router.get('/me',  requireAuth, requireRole('NANNY'), asyncHandler(nanniesController.getMyProfile))
router.get('/:id', asyncHandler(nanniesController.getById))
router.put('/me',  requireAuth, requireRole('NANNY'), asyncHandler(nanniesController.updateMyProfile))

// Document upload for nannies
router.post('/me/documents', requireAuth, requireRole('NANNY'), upload.single('file'), asyncHandler(nanniesController.uploadDocument))
router.get('/me/documents',  requireAuth, requireRole('NANNY'), asyncHandler(nanniesController.getDocuments))
router.delete('/me/documents/:docId', requireAuth, requireRole('NANNY'), asyncHandler(nanniesController.deleteDocument))

export default router
