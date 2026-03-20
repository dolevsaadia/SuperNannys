-- Drop the old 2-column unique index that only allowed ONE slot per day.
-- The correct constraint is the 3-column one: (nannyProfileId, dayOfWeek, fromTime)
-- which allows multiple slots per day with different start times.
DROP INDEX IF EXISTS "availabilities_nannyProfileId_dayOfWeek_key";

-- Drop duplicate lowercase version of the 3-column constraint (created by a
-- previous migration that ran alongside the original, leaving two copies).
ALTER TABLE "availabilities" DROP CONSTRAINT IF EXISTS "availabilities_nannyprofileid_dayofweek_fromtime_key";
