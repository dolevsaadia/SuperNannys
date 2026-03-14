-- ── User: structured address + phone verification + presence ──
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "city" TEXT NOT NULL DEFAULT '';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "streetName" TEXT NOT NULL DEFAULT '';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "houseNumber" TEXT NOT NULL DEFAULT '';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "postalCode" TEXT NOT NULL DEFAULT '';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "apartmentFloor" TEXT;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "latitude" DOUBLE PRECISION;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "longitude" DOUBLE PRECISION;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "phoneVerified" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "isOnline" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "lastSeenAt" TIMESTAMP(3);

-- ── NannyProfile: minimum hours, babysitting at home, structured address ──
ALTER TABLE "nanny_profiles" ADD COLUMN IF NOT EXISTS "minimumHoursPerBooking" DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE "nanny_profiles" ADD COLUMN IF NOT EXISTS "allowsBabysittingAtHome" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "nanny_profiles" ADD COLUMN IF NOT EXISTS "streetName" TEXT NOT NULL DEFAULT '';
ALTER TABLE "nanny_profiles" ADD COLUMN IF NOT EXISTS "houseNumber" TEXT NOT NULL DEFAULT '';
ALTER TABLE "nanny_profiles" ADD COLUMN IF NOT EXISTS "postalCode" TEXT NOT NULL DEFAULT '';
ALTER TABLE "nanny_profiles" ADD COLUMN IF NOT EXISTS "apartmentFloor" TEXT;

-- ── Booking: location type, structured address, estimated price ──
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "locationType" TEXT NOT NULL DEFAULT 'parent_home';
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "bookingCity" TEXT;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "bookingStreet" TEXT;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "bookingHouseNum" TEXT;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "bookingPostalCode" TEXT;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "bookingLat" DOUBLE PRECISION;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "bookingLng" DOUBLE PRECISION;
ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "estimatedPriceNis" INTEGER;

-- ── Date-specific availability ──
CREATE TABLE IF NOT EXISTS "nanny_date_availability" (
    "id" TEXT NOT NULL,
    "nannyProfileId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "startTime" TEXT NOT NULL,
    "endTime" TEXT NOT NULL,
    "isBlocked" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "nanny_date_availability_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "nanny_date_availability_nannyProfileId_date_startTime_key"
    ON "nanny_date_availability"("nannyProfileId", "date", "startTime");

ALTER TABLE "nanny_date_availability"
    DROP CONSTRAINT IF EXISTS "nanny_date_availability_nannyProfileId_fkey";
ALTER TABLE "nanny_date_availability"
    ADD CONSTRAINT "nanny_date_availability_nannyProfileId_fkey"
    FOREIGN KEY ("nannyProfileId") REFERENCES "nanny_profiles"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

-- ── Verification requests ──
CREATE TABLE IF NOT EXISTS "verification_requests" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "idCardUrl" TEXT,
    "idAppendixUrl" TEXT,
    "policeClearanceUrl" TEXT,
    "adminNotes" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),
    "reviewedBy" TEXT,

    CONSTRAINT "verification_requests_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "verification_requests"
    DROP CONSTRAINT IF EXISTS "verification_requests_userId_fkey";
ALTER TABLE "verification_requests"
    ADD CONSTRAINT "verification_requests_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
