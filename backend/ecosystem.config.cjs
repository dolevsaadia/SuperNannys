// PM2 Ecosystem Configuration — SuperNannys API
// Docs: https://pm2.keymetrics.io/docs/usage/application-declaration/
module.exports = {
  apps: [
    {
      name: 'supernannys-api',
      script: 'dist/server.js',
      cwd: '/var/www/SuperNannys/backend',
      instances: 1,
      exec_mode: 'fork',

      // ── Environment ──────────────────────────────────────
      env: {
        NODE_ENV: 'production',
        PORT: 8080,
      },

      // ── Logging ──────────────────────────────────────────
      error_file: '/var/www/SuperNannys/backend/logs/pm2-error.log',
      out_file: '/var/www/SuperNannys/backend/logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      max_memory_restart: '512M',

      // ── Auto-restart ─────────────────────────────────────
      autorestart: true,
      watch: false,
      max_restarts: 15,
      min_uptime: '10s',
      restart_delay: 3000,

      // ── Graceful shutdown ────────────────────────────────
      kill_timeout: 5000,
      listen_timeout: 10000,

      // ── Health check ─────────────────────────────────────
      // PM2 will check this URL after startup to confirm the app is ready
      // (requires pm2 plus or pm2-health-check module for auto-check)
    },
  ],
}
