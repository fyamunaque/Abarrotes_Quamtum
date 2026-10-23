BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "orders" ADD COLUMN "number" bigint;
CREATE UNIQUE INDEX "orders_number_idx" ON "orders" USING btree ("number");

--
-- Los pedidos que ya existen se numeran por fecha: 1001, 1002... (agregado a
-- mano; los nuevos los numera nextOrderNumber en el servidor).
--
UPDATE "orders" AS o
    SET "number" = n."number"
    FROM (
        SELECT "id", 1000 + ROW_NUMBER() OVER (ORDER BY "createdAt", "id") AS "number"
        FROM "orders"
    ) AS n
    WHERE o."id" = n."id";

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261023221241811-numero-de-pedido', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261023221241811-numero-de-pedido', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
