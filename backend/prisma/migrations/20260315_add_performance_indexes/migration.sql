-- Performance indexes for frequently queried columns

-- Bookings: parent lookups, nanny lookups, conflict detection, status filtering
CREATE INDEX IF NOT EXISTS "bookings_parentUserId_createdAt_idx" ON "bookings"("parentUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "bookings_nannyUserId_createdAt_idx" ON "bookings"("nannyUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "bookings_nannyUserId_status_startTime_endTime_idx" ON "bookings"("nannyUserId", "status", "startTime", "endTime");
CREATE INDEX IF NOT EXISTS "bookings_status_idx" ON "bookings"("status");
CREATE INDEX IF NOT EXISTS "bookings_recurringBookingId_idx" ON "bookings"("recurringBookingId");

-- Messages: chat listing by booking
CREATE INDEX IF NOT EXISTS "messages_bookingId_createdAt_idx" ON "messages"("bookingId", "createdAt");
CREATE INDEX IF NOT EXISTS "messages_fromUserId_idx" ON "messages"("fromUserId");

-- Reviews: rating aggregation by reviewee
CREATE INDEX IF NOT EXISTS "reviews_revieweeUserId_idx" ON "reviews"("revieweeUserId");
CREATE INDEX IF NOT EXISTS "reviews_reviewerUserId_idx" ON "reviews"("reviewerUserId");

-- Earnings: nanny earnings lookup and payout filtering
CREATE INDEX IF NOT EXISTS "earnings_nannyUserId_isPaid_idx" ON "earnings"("nannyUserId", "isPaid");

-- Devices: user device lookups for push notifications
CREATE INDEX IF NOT EXISTS "devices_userId_idx" ON "devices"("userId");

-- Notifications: user notification feed
CREATE INDEX IF NOT EXISTS "notifications_userId_isRead_createdAt_idx" ON "notifications"("userId", "isRead", "createdAt");

-- NannyProfile: search filtering by city/rating and availability
CREATE INDEX IF NOT EXISTS "nanny_profiles_city_rating_idx" ON "nanny_profiles"("city", "rating");
CREATE INDEX IF NOT EXISTS "nanny_profiles_isAvailable_rating_idx" ON "nanny_profiles"("isAvailable", "rating");

-- RecurringBookings: parent/nanny lookups
CREATE INDEX IF NOT EXISTS "recurring_bookings_parentUserId_status_idx" ON "recurring_bookings"("parentUserId", "status");
CREATE INDEX IF NOT EXISTS "recurring_bookings_nannyUserId_status_idx" ON "recurring_bookings"("nannyUserId", "status");

-- VerificationRequests: user lookup with status
CREATE INDEX IF NOT EXISTS "verification_requests_userId_status_idx" ON "verification_requests"("userId", "status");
