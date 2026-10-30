BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "orders" ADD COLUMN "deliveryCode" text;
ALTER TABLE "orders" ADD COLUMN "deliveredWithoutCodeReason" text;
CREATE UNIQUE INDEX "orders_delivery_code_idx" ON "orders" USING btree ("deliveryCode");

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261030032219408-codigo-de-entrega', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261030032219408-codigo-de-entrega', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
