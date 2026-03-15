import { PrismaClient } from '@prisma/client'
import { logger } from './shared/utils/logger'

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined
}

const isDev = process.env.NODE_ENV === 'development'

export const prisma: PrismaClient =
  global.__prisma ??
  new PrismaClient({
    log: isDev
      ? [
          { emit: 'event', level: 'query' },
          { emit: 'stdout', level: 'error' },
          { emit: 'stdout', level: 'warn' },
        ]
      : [
          { emit: 'event', level: 'query' },
          { emit: 'stdout', level: 'error' },
        ],
  })

// Log slow queries (>200ms in prod, >500ms in dev) for performance monitoring
const SLOW_QUERY_MS = isDev ? 500 : 200;
(prisma.$on as any)('query', (e: any) => {
  const durationMs = e.duration as number
  if (durationMs > SLOW_QUERY_MS) {
    logger.warn('Slow query detected', {
      query: (e.query as string).substring(0, 200),
      durationMs,
      params: (e.params as string).substring(0, 100),
    })
  }
})

if (process.env.NODE_ENV !== 'production') {
  global.__prisma = prisma
}

export async function connectDB(): Promise<void> {
  await prisma.$connect()
  logger.info('✅ PostgreSQL connected via Prisma')
}

export async function disconnectDB(): Promise<void> {
  await prisma.$disconnect()
  logger.info('PostgreSQL disconnected')
}
