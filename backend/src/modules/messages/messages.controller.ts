import { Request, Response } from 'express'
import { ok, created } from '../../shared/utils/response'
import { messagesService } from './messages.service'
import { sendMessageSchema } from './messages.validation'

export const messagesController = {
  async getConversations(req: Request, res: Response): Promise<void> {
    const result = await messagesService.getConversations(req.user!.userId, req.user!.role)
    ok(res, result)
  },

  async getMessages(req: Request, res: Response): Promise<void> {
    const { page = '1', limit = '50' } = req.query as Record<string, string>
    const pageNum = Math.max(1, parseInt(page))
    const limitNum = Math.min(100, parseInt(limit))
    const result = await messagesService.getMessages(req.user!.userId, req.params.bookingId, pageNum, limitNum)
    ok(res, result)
  },

  async sendMessage(req: Request, res: Response): Promise<void> {
    const { text } = sendMessageSchema.parse(req.body)
    const message = await messagesService.sendMessage(req.user!.userId, req.params.bookingId, text)
    created(res, message)
  },
}
