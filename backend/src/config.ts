import dotenv from 'dotenv'
dotenv.config()

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '8080', 10),
  clientUrl: process.env.CLIENT_URL || 'http://localhost:3000',
  // Public base URL for constructing asset URLs (uploads, avatars).
  // Falls back to request-based URL construction if not set.
  publicBaseUrl: process.env.PUBLIC_BASE_URL || '',

  jwt: {
    secret: process.env.JWT_SECRET || 'fallback-secret-CHANGE-in-production-32chars+',
    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'refresh-fallback-secret-CHANGE-in-production-48chars+',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },

  google: {
    // Web client ID (type 3) from google-services.json
    clientId: process.env.GOOGLE_CLIENT_ID || '768121322557-onvanoq8dpr74bdrg40ne9iqpishgbn7.apps.googleusercontent.com',
    // iOS client ID (type 2) from GoogleService-Info.plist
    iosClientId: process.env.GOOGLE_IOS_CLIENT_ID || '768121322557-3reccv7capojqi11t3an73eir4178fc6.apps.googleusercontent.com',
    // Android client ID (type 1) from google-services.json
    androidClientId: process.env.GOOGLE_ANDROID_CLIENT_ID || '768121322557-gs4qufuh0j2lfrag98eepfiebjk3dg9k.apps.googleusercontent.com',
    get allClientIds(): string[] {
      return [this.clientId, this.iosClientId, this.androidClientId].filter((id) => id !== '')
    },
    get isConfigured(): boolean {
      return this.clientId !== '' && this.clientId !== 'your-google-client-id'
    },
  },

  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
  },

  payments: {
    enabled: process.env.ENABLE_PAYMENTS === 'true',
    stripeSecretKey: process.env.STRIPE_SECRET_KEY || '',
    stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '',
    stripePublishableKey: process.env.STRIPE_PUBLISHABLE_KEY || '',
  },

  upload: {
    maxFileSizeMb: parseInt(process.env.MAX_FILE_SIZE_MB || '5', 10),
    uploadDir: process.env.UPLOAD_DIR || './uploads',
  },

  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX || '300', 10),
  },

  google_places: {
    apiKey: process.env.GOOGLE_PLACES_API_KEY || '',
    get isConfigured(): boolean {
      return this.apiKey !== ''
    },
  },

  platformFeePercent: 15,
}
