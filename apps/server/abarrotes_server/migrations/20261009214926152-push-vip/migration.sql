BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "device_tokens" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "token" text NOT NULL,
    "platform" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "device_tokens_token_idx" ON "device_tokens" USING btree ("token");
CREATE INDEX "device_tokens_user_idx" ON "device_tokens" USING btree ("userId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "users" ADD COLUMN "emailVerified" boolean NOT NULL DEFAULT false;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "device_tokens"
    ADD CONSTRAINT "device_tokens_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;


--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261009214926152-push-vip', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009214926152-push-vip', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
