import type { DocumentType } from '@prisma/client'
import { Request, Response } from 'express'
import { AppError } from '../../shared/errors/app-error'
import { ok } from '../../shared/utils/response'
import { nanniesService } from './nannies.service'
import { searchNanniesSchema, updateNannyProfileSchema, dateAvailabilitySchema, blockDateSchema } from './nannies.validation'

export const nanniesController = {
  async search(req: Request, res: Response): Promise<void> {
    const params = searchNanniesSchema.parse(req.query)
    const result = await nanniesService.search(params)
    ok(res, result)
  },

  async getMyProfile(req: Request, res: Response): Promise<void> {
    const profile = await nanniesService.getMyProfile(req.user!.userId)
    ok(res, profile)
  },

  async getById(req: Request, res: Response): Promise<void> {
    const result = await nanniesService.getById(req.params.id)
    ok(res, result)
  },

  async updateMyProfile(req: Request, res: Response): Promise<void> {
    const data = updateNannyProfileSchema.parse(req.body)
    const profile = await nanniesService.updateMyProfile(req.user!.userId, data)
    ok(res, profile)
  },

  async uploadDocument(req: Request, res: Response): Promise<void> {
    if (!req.file) {
      throw new AppError('No file uploaded', 400)
    }
    const validTypes: DocumentType[] = ['ID_CARD', 'POLICE_CHECK', 'FIRST_AID_CERT', 'CHILDCARE_CERT', 'OTHER']
    const type = (req.body.type || 'OTHER') as DocumentType
    if (!validTypes.includes(type)) {
      throw new AppError(`Invalid document type. Must be one of: ${validTypes.join(', ')}`, 400)
    }
    const url = `/uploads/${req.file.filename}`
    const doc = await nanniesService.addDocument(req.user!.userId, type, url)
    ok(res, doc)
  },

  async getDocuments(req: Request, res: Response): Promise<void> {
    const docs = await nanniesService.getDocuments(req.user!.userId)
    ok(res, docs)
  },

  async deleteDocument(req: Request, res: Response): Promise<void> {
    await nanniesService.deleteDocument(req.user!.userId, req.params.docId)
    ok(res, { deleted: true })
  },

  // ── Date availability management ─────────────────────────
  async upsertDateAvailability(req: Request, res: Response): Promise<void> {
    const data = dateAvailabilitySchema.parse(req.body)
    const result = await nanniesService.upsertDateAvailability(req.user!.userId, {
      date: new Date(data.date),
      startTime: data.startTime,
      endTime: data.endTime,
      isBlocked: data.isBlocked ?? false,
    })
    ok(res, result)
  },

  async deleteDateAvailability(req: Request, res: Response): Promise<void> {
    await nanniesService.deleteDateAvailability(req.user!.userId, req.params.slotId)
    ok(res, { deleted: true })
  },

  async blockDate(req: Request, res: Response): Promise<void> {
    const data = blockDateSchema.parse(req.body)
    const result = await nanniesService.blockDate(req.user!.userId, new Date(data.date))
    ok(res, result)
  },

  async getAvailabilityCalendar(req: Request, res: Response): Promise<void> {
    const { month } = req.query // format: "2026-03"
    const result = await nanniesService.getAvailabilityCalendar(req.params.id, month as string)
    ok(res, result)
  },
}
