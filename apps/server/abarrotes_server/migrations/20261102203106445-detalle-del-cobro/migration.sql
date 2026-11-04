BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "order_items" ADD COLUMN "listUnitPriceCents" bigint NOT NULL DEFAULT 0;
ALTER TABLE "order_items" ADD COLUMN "lineTotalCents" bigint NOT NULL DEFAULT 0;
ALTER TABLE "order_items" ADD COLUMN "isGift" boolean NOT NULL DEFAULT false;
ALTER TABLE "order_items" ADD COLUMN "promotions" json;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "orders" ADD COLUMN "subtotalCents" bigint NOT NULL DEFAULT 0;
ALTER TABLE "orders" ADD COLUMN "discountCents" bigint NOT NULL DEFAULT 0;

--
-- Los pedidos de antes: sin descuentos, cada línea a cantidad × precio.
--
UPDATE "order_items" SET "listUnitPriceCents" = "unitPriceCents",
    "lineTotalCents" = "quantity" * "unitPriceCents";
UPDATE "orders" SET "subtotalCents" = "totalCents", "discountCents" = 0;

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261102203106445-detalle-del-cobro', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261102203106445-detalle-del-cobro', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
