-- CreateTable
CREATE TABLE "chat_hides" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "otherUserId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_hides_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "chat_hides_userId_otherUserId_key" ON "chat_hides"("userId", "otherUserId");

-- AddForeignKey
ALTER TABLE "chat_hides" ADD CONSTRAINT "chat_hides_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
