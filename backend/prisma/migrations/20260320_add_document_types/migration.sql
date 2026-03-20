-- Add new document types to the DocumentType enum for verification flow.
-- ID_APPENDIX: back side of Israeli ID
-- POLICE_CLEARANCE: ethics/background check certificate
ALTER TYPE "DocumentType" ADD VALUE IF NOT EXISTS 'ID_APPENDIX';
ALTER TYPE "DocumentType" ADD VALUE IF NOT EXISTS 'POLICE_CLEARANCE';
