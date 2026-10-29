BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "users" ADD COLUMN "dni" text;
ALTER TABLE "users" ADD COLUMN "termsVersion" text;
ALTER TABLE "users" ADD COLUMN "termsAcceptedAt" timestamp without time zone;
CREATE UNIQUE INDEX "users_dni_idx" ON "users" USING btree ("dni");

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261029011401737-perfil-del-cliente', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261029011401737-perfil-del-cliente', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
