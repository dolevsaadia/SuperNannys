-- CreateIndex
CREATE INDEX IF NOT EXISTS "nanny_date_availability_nannyProfileId_date_isBlocked_idx" ON "nanny_date_availability"("nannyProfileId", "date", "isBlocked");
