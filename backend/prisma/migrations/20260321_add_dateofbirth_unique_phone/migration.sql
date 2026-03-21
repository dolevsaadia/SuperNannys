-- Add dateOfBirth column
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "dateOfBirth" TIMESTAMP(3);

-- Clear duplicate phone values (keep most recent user, null-out older duplicates)
-- This ensures the unique constraint can be applied safely.
UPDATE "users" u
SET "phone" = NULL
WHERE "phone" IS NOT NULL
  AND "id" != (
    SELECT "id" FROM "users" u2
    WHERE u2."phone" = u."phone"
    ORDER BY u2."createdAt" DESC
    LIMIT 1
  );

-- Add unique constraint on phone (PostgreSQL allows multiple NULLs)
CREATE UNIQUE INDEX IF NOT EXISTS "users_phone_key" ON "users"("phone");
