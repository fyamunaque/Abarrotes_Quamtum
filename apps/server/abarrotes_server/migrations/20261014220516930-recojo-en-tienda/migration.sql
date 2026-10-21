BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "orders" ADD COLUMN "fulfillmentType" text NOT NULL DEFAULT 'delivery'::text;
ALTER TABLE "orders" ADD COLUMN "pickupCode" text;
ALTER TABLE "orders" ADD COLUMN "readyForPickupAt" timestamp without time zone;
ALTER TABLE "orders" ALTER COLUMN "deliveryAddress" DROP NOT NULL;
CREATE UNIQUE INDEX "orders_pickup_code_idx" ON "orders" USING btree ("pickupCode");

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261014220516930-recojo-en-tienda', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014220516930-recojo-en-tienda', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
