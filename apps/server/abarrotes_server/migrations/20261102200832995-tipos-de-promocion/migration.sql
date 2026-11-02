BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "promotions" DROP CONSTRAINT IF EXISTS "promotions_fk_0";
ALTER TABLE "promotions" ADD COLUMN "type" text NOT NULL DEFAULT 'specialPrice'::text;
ALTER TABLE "promotions" ADD COLUMN "percent" bigint;
ALTER TABLE "promotions" ADD COLUMN "buyQuantity" bigint;
ALTER TABLE "promotions" ADD COLUMN "payQuantity" bigint;
ALTER TABLE "promotions" ADD COLUMN "giftProductId" uuid;
ALTER TABLE "promotions" ADD COLUMN "giftQuantity" bigint;
ALTER TABLE "promotions" ALTER COLUMN "promoPriceCents" DROP NOT NULL;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "promotions"
    ADD CONSTRAINT "promotions_fk_1"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
ALTER TABLE ONLY "promotions"
    ADD CONSTRAINT "promotions_fk_0"
    FOREIGN KEY("giftProductId")
    REFERENCES "products"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261102200832995-tipos-de-promocion', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261102200832995-tipos-de-promocion', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
