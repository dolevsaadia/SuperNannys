# SuperNanny — Production Babysitter Marketplace

A full-stack production-ready babysitter marketplace app built with:
- **Mobile**: Flutter (iOS + Android)
- **Backend**: Node.js + TypeScript + Express + Prisma
- **Database**: PostgreSQL
- **Real-time**: Socket.io (live chat + notifications)
- **Payments**: Stripe (feature-flagged, activate when ready)

---

## Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) ← easiest
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.3+)
- [Node.js](https://nodejs.org/) 20+

### 1. Clone & Setup

```bash
git clone <your-repo>
cd SuperNanny
chmod +x setup.sh
./setup.sh --dev
```

The setup script will:
1. Create `backend/.env` from the example
2. Start PostgreSQL in Docker
3. Run Prisma migrations (create all DB tables)
4. Seed demo data (10 nannies + 3 parents + 1 admin)
5. Start the backend dev server
6. Install Flutter packages

### 2. Run the Flutter App

```bash
cd app
flutter run          # connected device / emulator
flutter run -d ios   # iOS simulator
```

> **Physical device?** Edit `app/lib/core/constants/app_constants.dart` and replace `localhost` with your Mac's IP address (e.g. `192.168.1.10`).

---

## Project Structure

```
SuperNanny/
├── setup.sh                 ← Main setup script
├── docker-compose.yml       ← PostgreSQL + Backend
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma    ← All DB table definitions
│   │   └── seed.ts          ← Demo data seeder
│   └── src/
│       ├── routes/          ← All API endpoints
│       ├── socket/          ← Real-time chat (Socket.io)
│       └── ...
└── app/
    └── lib/
        ├── core/            ← Theme, router, models, network
        └── features/        ← All screens organized by feature
```

---

## Demo Credentials

| Role   | Email                     | Password    |
|--------|---------------------------|-------------|
| Parent | parent1@supernanny.app    | Super1234!  |
| Nanny  | nanny1@supernanny.app     | Super1234!  |
| Admin  | admin@supernanny.app      | Super1234!  |

---

## API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login with email/password |
| POST | `/api/auth/google` | Google Sign-In |
| GET | `/api/auth/me` | Get current user |
| GET | `/api/nannies` | Search nannies with filters |
| GET | `/api/nannies/:id` | Nanny profile + reviews |
| PUT | `/api/nannies/me` | Update nanny profile |
| POST | `/api/bookings` | Create booking |
| GET | `/api/bookings` | List user's bookings |
| PATCH | `/api/bookings/:id/status` | Accept/decline/cancel/complete |
| GET | `/api/messages/conversations` | List chat conversations |
| GET | `/api/messages/:bookingId` | Get messages for booking |
| POST | `/api/messages/:bookingId` | Send message |
| POST | `/api/reviews` | Submit review |
| GET | `/api/admin/stats` | Admin dashboard stats |
| GET | `/api/payments/intent` | Create Stripe payment intent (if enabled) |
| GET | `/health` | Health check |

---

## Enabling Payments (Stripe)

1. Create a [Stripe account](https://stripe.com)
2. Get your API keys from the Stripe dashboard
3. Edit `backend/.env`:
   ```
   ENABLE_PAYMENTS=true
   STRIPE_SECRET_KEY=sk_live_...
   STRIPE_PUBLISHABLE_KEY=pk_live_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```
4. Restart the backend

---

## Database Management

```bash
cd backend

# Open Prisma Studio (visual DB browser)
npm run db:studio

# Reset and re-seed
npm run db:reset

# View schema
cat prisma/schema.prisma
```

---

## App Features

### For Parents
- Search nannies by city, rate, experience, language, skills
- View full nanny profile with reviews and availability calendar
- Book a nanny with date/time picker
- Real-time chat with nanny
- Track booking status (requested → accepted → completed)
- Leave reviews after completed bookings

### For Nannies
- Set up detailed profile with photo, bio, rates, languages, skills
- Manage weekly availability schedule
- Accept/decline booking requests
- Real-time chat with parents
- Dashboard with earnings, job history, and stats

### For Admins
- Platform statistics dashboard
- User management (activate/deactivate accounts)
- Booking oversight
- Revenue tracking

---

## Tech Stack Details

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.3+ with Material 3 |
| State | Riverpod 2 |
| Navigation | GoRouter 13 |
| HTTP | Dio 5 with JWT interceptor |
| Real-time | Socket.io |
| Backend | Node.js 20 + Express 4 |
| Language | TypeScript 5 (strict) |
| ORM | Prisma 5 |
| Database | PostgreSQL 16 |
| Auth | JWT + bcrypt + Google OAuth |
| Validation | Zod |
| Security | Helmet, CORS, rate limiting |
| Payments | Stripe (feature-flagged) |
| Push | Firebase Cloud Messaging (optional) |
| Container | Docker + Docker Compose |
