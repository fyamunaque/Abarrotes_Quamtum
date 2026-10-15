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
CREATE TABLE "store_settings" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "singleton" boolean NOT NULL DEFAULT true,
    "name" text NOT NULL,
    "address" text NOT NULL,
    "reference" text,
    "phone" text,
    "openingHours" text,
    "pickupInstructions" text,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedByUserId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "store_settings_singleton_idx" ON "store_settings" USING btree ("singleton");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "store_settings"
    ADD CONSTRAINT "store_settings_fk_0"
    FOREIGN KEY("updatedByUserId")
    REFERENCES "users"("id")
    ON DELETE SET NULL
    ON UPDATE CASCADE;


--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261015032450431-datos-de-la-tienda', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261015032450431-datos-de-la-tienda', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
