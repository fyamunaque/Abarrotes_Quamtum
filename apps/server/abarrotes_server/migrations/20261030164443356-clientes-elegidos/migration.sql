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
CREATE TABLE "promotion_recipients" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "promotionId" uuid NOT NULL,
    "vipCustomerId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "promotion_recipients_pair_idx" ON "promotion_recipients" USING btree ("promotionId", "vipCustomerId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "promotion_recipients"
    ADD CONSTRAINT "promotion_recipients_fk_0"
    FOREIGN KEY("promotionId")
    REFERENCES "promotions"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;
ALTER TABLE ONLY "promotion_recipients"
    ADD CONSTRAINT "promotion_recipients_fk_1"
    FOREIGN KEY("vipCustomerId")
    REFERENCES "vip_customers"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;


--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261030164443356-clientes-elegidos', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261030164443356-clientes-elegidos', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
