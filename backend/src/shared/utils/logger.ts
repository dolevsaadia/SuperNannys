import winston from 'winston'

const isDev = process.env.NODE_ENV !== 'production'

export const logger = winston.createLogger({
  level: isDev ? 'debug' : 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    isDev
      ? winston.format.combine(winston.format.colorize(), winston.format.printf(
          ({ timestamp, level, message, ...meta }) =>
            `${timestamp} ${level}: ${message}${Object.keys(meta).length ? ' ' + JSON.stringify(meta) : ''}`
        ))
      : winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    ...(isDev
      ? []
      : [
          new winston.transports.File({ filename: 'logs/error.log', level: 'error', maxsize: 10_000_000, maxFiles: 5 }),
          new winston.transports.File({ filename: 'logs/combined.log', maxsize: 10_000_000, maxFiles: 5 }),
        ]),
  ],
})

/**
 * Create a child logger with context fields that appear in every log entry.
 * Usage: const log = childLogger({ module: 'sessions', bookingId })
 */
export function childLogger(meta: Record<string, unknown>) {
  return logger.child(meta)
}
