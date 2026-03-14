import 'dotenv/config'
import fs from 'fs'
import { createApp } from './app'
import { connectDB, disconnectDB } from './db'
import { config } from './config'
import { logger } from './shared/utils/logger'
import { runRecurringGeneration } from './jobs/recurring-generation'

async function main() {
  // Ensure upload and log directories exist
  for (const dir of [config.upload.uploadDir, 'logs']) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true })
    }
  }

  await connectDB()

  const { httpServer } = createApp()

  httpServer.listen(config.port, () => {
    logger.info('SuperNanny API started', {
      port: config.port,
      env: config.nodeEnv,
      payments: config.payments.enabled,
    })

    // Run recurring generation on startup (after 10s delay) then every 24h
    setTimeout(() => {
      runRecurringGeneration().catch(err => logger.error('Recurring generation startup run failed', { err }))
    }, 10_000)
    setInterval(() => {
      runRecurringGeneration().catch(err => logger.error('Recurring generation scheduled run failed', { err }))
    }, 24 * 60 * 60 * 1000)
  })

  const shutdown = async (signal: string) => {
    logger.info('Shutdown signal received', { signal })
    await disconnectDB()
    process.exit(0)
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'))
  process.on('SIGINT', () => shutdown('SIGINT'))
  process.on('uncaughtException', (err) => {
    logger.error('Uncaught exception', { message: err.message, stack: err.stack })
    // Attempt graceful shutdown; PM2 will auto-restart
    disconnectDB().catch(() => {}).finally(() => process.exit(1))
  })
  process.on('unhandledRejection', (reason) => {
    // Log but do NOT exit — unhandled rejections are recoverable.
    // Exiting on every rejection causes unnecessary downtime.
    logger.error('Unhandled promise rejection', {
      reason: reason instanceof Error ? { message: reason.message, stack: reason.stack } : reason,
    })
  })
}

main().catch(err => {
  console.error('Fatal startup error:', err)
  process.exit(1)
})
