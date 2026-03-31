-- Sprint 1: Foundation & Authentication Database Schema
-- Generated from migration file 1700000000001-CreateUserTable.ts

-- Create user_management schema if not exists
CREATE SCHEMA IF NOT EXISTS "user_management";

-- Create UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create subscription plan enum type
DO $$ BEGIN
    CREATE TYPE user_management.subscription_plan AS ENUM ('FREE', 'PREMIUM', 'BUSINESS');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create users table
CREATE TABLE IF NOT EXISTS user_management.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    "firstName" VARCHAR(100) NOT NULL,
    "lastName" VARCHAR(100) NOT NULL,
    avatar VARCHAR(255),
    "isEmailVerified" BOOLEAN DEFAULT false,
    "subscriptionPlan" user_management.subscription_plan DEFAULT 'FREE',
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    "storageUsed" BIGINT DEFAULT 0,
    preferences JSONB,
    "loginAttempts" INT DEFAULT 0,
    "lockedUntil" TIMESTAMPTZ,
    "emailVerificationToken" VARCHAR(255),
    "emailVerificationExpires" TIMESTAMPTZ,
    "passwordResetToken" VARCHAR(255),
    "passwordResetExpires" TIMESTAMPTZ,
    "refreshTokens" TEXT[],
    "lastLogin" TIMESTAMPTZ,
    "createdAt" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMPTZ
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS IDX_USER_EMAIL ON user_management.users(email);
CREATE INDEX IF NOT EXISTS IDX_USER_EMAIL_VERIFICATION_TOKEN ON user_management.users("emailVerificationToken") WHERE "emailVerificationToken" IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_USER_PASSWORD_RESET_TOKEN ON user_management.users("passwordResetToken") WHERE "passwordResetToken" IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_USER_DELETED_AT ON user_management.users("deletedAt") WHERE "deletedAt" IS NULL;
CREATE INDEX IF NOT EXISTS IDX_USER_SUBSCRIPTION_PLAN ON user_management.users("subscriptionPlan");

-- Create trigger for updatedAt
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists before creating
DROP TRIGGER IF EXISTS update_user_management_users_updated_at ON user_management.users;

CREATE TRIGGER update_user_management_users_updated_at
BEFORE UPDATE ON user_management.users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Validation query
SELECT
    'Database initialized successfully!' as message,
    COUNT(*) as tables_created
FROM information_schema.tables
WHERE table_schema = 'user_management';