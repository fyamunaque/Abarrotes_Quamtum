BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "inventory_movements" ADD COLUMN "orderId" uuid;
CREATE INDEX "inventory_movements_order_idx" ON "inventory_movements" USING btree ("orderId");
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "inventory_movements"
    ADD CONSTRAINT "inventory_movements_fk_2"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Los movimientos de antes: cada uno a su pedido, por el motivo que
-- escribía el servidor ("Pedido <id>" o "Cancelación del pedido <id>"),
-- solo si ese pedido existe.
--
UPDATE "inventory_movements" AS m
    SET "orderId" = o."id"
    FROM "orders" AS o
    WHERE m."orderId" IS NULL
      AND m."reason" IN (
          'Pedido ' || o."id"::text,
          'Cancelación del pedido ' || o."id"::text
      );

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261030153440774-filtros-de-inventario', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261030153440774-filtros-de-inventario', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
