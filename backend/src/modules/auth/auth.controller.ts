import { Request, Response } from 'express'
import { ok, created } from '../../shared/utils/response'
import { authService } from './auth.service'
import { registerSchema, loginSchema, googleSignInSchema } from './auth.validation'

export const authController = {
  async register(req: Request, res: Response): Promise<void> {
    const data = registerSchema.parse(req.body)
    const result = await authService.register(data)
    created(res, result)
  },

  async login(req: Request, res: Response): Promise<void> {
    const data = loginSchema.parse(req.body)
    const result = await authService.login(data)
    ok(res, result)
  },

  async googleSignIn(req: Request, res: Response): Promise<void> {
    const data = googleSignInSchema.parse(req.body)
    const result = await authService.googleSignIn(data)
    ok(res, result)
  },

  async getMe(req: Request, res: Response): Promise<void> {
    const user = await authService.getMe(req.user!.userId)
    ok(res, user)
  },
}
