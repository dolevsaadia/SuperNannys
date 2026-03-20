import 'dotenv/config'
import fs from 'fs'
import { createApp } from './app'
import { connectDB, disconnectDB } from './db'
import { config } from './config'
import { logger } from './shared/utils/logger'
import { runRecurringGeneration } from './jobs/recurring-generation'

// ── Graceful Shutdown ────────────────────────────────────────
let isShuttingDown = false
const SHUTDOWN_TIMEOUT_MS = 10_000

async function gracefulShutdown(signal: string, httpServer?: ReturnType<typeof import('http').createServer>) {
  if (isShuttingDown) return
  isShuttingDown = true
  logger.info('Shutdown signal received', { signal })

  // Stop accepting new connections
  if (httpServer) {
    httpServer.close(() => logger.info('HTTP server closed'))
  }

  // Force exit after timeout if graceful shutdown stalls
  const forceTimer = setTimeout(() => {
    logger.error('Graceful shutdown timed out, forcing exit')
    process.exit(1)
  }, SHUTDOWN_TIMEOUT_MS)
  forceTimer.unref() // Don't keep process alive just for this timer

  try {
    await disconnectDB()
  } catch (err) {
    logger.error('Error during DB disconnect', { err })
  }
  process.exit(0)
}

// ── Main ─────────────────────────────────────────────────────
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
      pid: process.pid,
    })

    // Run recurring generation on startup (after 10s delay) then every 24h
    setTimeout(() => {
      runRecurringGeneration().catch(err => logger.error('Recurring generation startup run failed', { err }))
    }, 10_000)
    setInterval(() => {
      runRecurringGeneration().catch(err => logger.error('Recurring generation scheduled run failed', { err }))
    }, 24 * 60 * 60 * 1000)
  })

  // ── Process signal handlers ──────────────────────────────
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM', httpServer))
  process.on('SIGINT', () => gracefulShutdown('SIGINT', httpServer))

  process.on('uncaughtException', (err) => {
    logger.error('Uncaught exception — initiating shutdown', {
      message: err.message,
      stack: err.stack,
      name: err.name,
    })
    // uncaughtException means state is unreliable — shutdown gracefully, PM2 will restart
    gracefulShutdown('uncaughtException', httpServer)
  })

  process.on('unhandledRejection', (reason) => {
    // Log but do NOT exit — unhandled rejections are recoverable
    logger.error('Unhandled promise rejection', {
      reason: reason instanceof Error
        ? { message: reason.message, stack: reason.stack, name: reason.name }
        : reason,
    })
  })
}

main().catch(err => {
  console.error('Fatal startup error:', err)
  process.exit(1)
})
