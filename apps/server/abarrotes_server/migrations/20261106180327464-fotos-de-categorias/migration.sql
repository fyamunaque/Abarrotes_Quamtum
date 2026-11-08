BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "categories" ADD COLUMN "description" text;
ALTER TABLE "categories" ADD COLUMN "imageUrl" text;

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261106180327464-fotos-de-categorias', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261106180327464-fotos-de-categorias', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
