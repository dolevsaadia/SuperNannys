import 'dotenv/config'
import fs from 'fs'
import { createApp } from './app'
import { connectDB, disconnectDB } from './db'
import { config } from './config'
import { logger } from './shared/utils/logger'

async function main() {
  // Ensure upload directory exists
  if (!fs.existsSync(config.upload.uploadDir)) {
    fs.mkdirSync(config.upload.uploadDir, { recursive: true })
  }

  await connectDB()

  const { httpServer } = createApp()

  httpServer.listen(config.port, () => {
    logger.info(`🚀 SuperNanny API → http://localhost:${config.port}`)
    logger.info(`📌 Environment  : ${config.nodeEnv}`)
  })

  const shutdown = async (signal: string) => {
    logger.info(`${signal} received — shutting down gracefully`)
    await disconnectDB()
    process.exit(0)
  }

  process.on('SIGTERM', () => shutdown('SIGTERM'))
  process.on('SIGINT', () => shutdown('SIGINT'))
  process.on('uncaughtException', err => { logger.error('Uncaught exception', { err }); process.exit(1) })
  process.on('unhandledRejection', err => { logger.error('Unhandled rejection', { err }); process.exit(1) })
}

main().catch(err => {
  console.error('Fatal startup error:', err)
  process.exit(1)
})
