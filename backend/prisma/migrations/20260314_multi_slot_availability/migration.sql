-- AlterTable: Change unique constraint from (nannyProfileId, dayOfWeek) to (nannyProfileId, dayOfWeek, fromTime)
-- This allows multiple time slots per day for nanny availability

-- Drop the old unique constraint
ALTER TABLE "availabilities" DROP CONSTRAINT IF EXISTS "availabilities_nannyProfileId_dayOfWeek_key";

-- Create the new unique constraint that includes fromTime
ALTER TABLE "availabilities" ADD CONSTRAINT "availabilities_nannyProfileId_dayOfWeek_fromTime_key" UNIQUE ("nannyProfileId", "dayOfWeek", "fromTime");
