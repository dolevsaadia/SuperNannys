-- AlterTable
ALTER TABLE "users" ADD COLUMN "deletedByAdminId" TEXT;
ALTER TABLE "users" ADD COLUMN "preDeleteName" TEXT;
ALTER TABLE "users" ADD COLUMN "preDeleteEmail" TEXT;
