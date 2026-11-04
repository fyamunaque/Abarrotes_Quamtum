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
CREATE TABLE "order_promo_code_uses" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "orderId" uuid NOT NULL,
    "redemptionId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "order_promo_code_uses_pair_idx" ON "order_promo_code_uses" USING btree ("orderId", "redemptionId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "promo_code_allowed_emails" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "promoCodeId" uuid NOT NULL,
    "email" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "promo_code_allowed_emails_pair_idx" ON "promo_code_allowed_emails" USING btree ("promoCodeId", "email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "promo_code_redemptions" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "promoCodeId" uuid NOT NULL,
    "userId" uuid NOT NULL,
    "activatedAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "promo_code_redemptions_pair_idx" ON "promo_code_redemptions" USING btree ("promoCodeId", "userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "promo_codes" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "code" text NOT NULL,
    "active" boolean NOT NULL DEFAULT true,
    "startDate" timestamp without time zone NOT NULL,
    "endDate" timestamp without time zone NOT NULL,
    "benefitDays" bigint,
    "maxRedemptions" bigint,
    "usesPerCustomer" bigint,
    "minPurchaseCents" bigint,
    "newCustomersOnly" boolean NOT NULL DEFAULT false,
    "eligibility" text NOT NULL DEFAULT 'everyone'::text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "promo_codes_code_idx" ON "promo_codes" USING btree ("code");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "promotions" ADD COLUMN "promoCodeId" uuid;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "order_promo_code_uses"
    ADD CONSTRAINT "order_promo_code_uses_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
ALTER TABLE ONLY "order_promo_code_uses"
    ADD CONSTRAINT "order_promo_code_uses_fk_1"
    FOREIGN KEY("redemptionId")
    REFERENCES "promo_code_redemptions"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "promo_code_allowed_emails"
    ADD CONSTRAINT "promo_code_allowed_emails_fk_0"
    FOREIGN KEY("promoCodeId")
    REFERENCES "promo_codes"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "promo_code_redemptions"
    ADD CONSTRAINT "promo_code_redemptions_fk_0"
    FOREIGN KEY("promoCodeId")
    REFERENCES "promo_codes"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
ALTER TABLE ONLY "promo_code_redemptions"
    ADD CONSTRAINT "promo_code_redemptions_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "promotions"
    ADD CONSTRAINT "promotions_fk_2"
    FOREIGN KEY("promoCodeId")
    REFERENCES "promo_codes"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261102232249740-codigos-promocionales', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261102232249740-codigos-promocionales', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
