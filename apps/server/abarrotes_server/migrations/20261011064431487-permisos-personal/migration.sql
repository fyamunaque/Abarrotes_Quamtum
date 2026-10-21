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
CREATE TABLE "audit_logs" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "actorUserId" uuid,
    "action" text NOT NULL,
    "targetEmail" text,
    "details" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "audit_logs_created_idx" ON "audit_logs" USING btree ("createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_members" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "email" text NOT NULL,
    "roleId" uuid NOT NULL,
    "addedByUserId" uuid,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "active" boolean NOT NULL DEFAULT true
);

-- Indexes
CREATE UNIQUE INDEX "staff_members_email_idx" ON "staff_members" USING btree ("email");
CREATE INDEX "staff_members_role_idx" ON "staff_members" USING btree ("roleId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_roles" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "name" text NOT NULL,
    "permissions" json NOT NULL,
    "isSystem" boolean NOT NULL DEFAULT false,
    "active" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "staff_roles_name_idx" ON "staff_roles" USING btree ("name");

--
-- DATOS (agregado a mano): los roles iniciales y el personal que ya existía
-- según users.role, antes de borrar esa columna. Una base nueva no pasa por
-- aquí (usa definition.sql): ahí los roles los crea StaffBootstrap al
-- arrancar.
--
INSERT INTO "staff_roles" ("name", "permissions", "isSystem") VALUES
    ('Administrador', '["productsView","productsManage","categoriesManage","ordersView","ordersUpdateStatus","inventoryView","inventoryAdjust","promotionsManage","vipView","vipManage","statsView","customersView","staffManage"]'::json, true),
    ('Almacenero', '["productsView","inventoryView","inventoryAdjust","statsView"]'::json, false),
    ('Cajera', '["productsView","ordersView","ordersUpdateStatus","customersView"]'::json, false),
    ('Solo lectura', '["productsView","ordersView"]'::json, false)
    ON CONFLICT ("name") DO NOTHING;

-- admin → Administrador; staff → Solo lectura, hasta que un admin le asigne
-- otro rol.
INSERT INTO "staff_members" ("email", "roleId")
    SELECT u."email", r."id"
    FROM "users" u
    JOIN "staff_roles" r ON r."name" =
        CASE u."role" WHEN 'admin' THEN 'Administrador' ELSE 'Solo lectura' END
    WHERE u."role" IN ('admin', 'staff')
    ON CONFLICT ("email") DO NOTHING;

INSERT INTO "audit_logs" ("action", "targetEmail", "details")
    SELECT 'staffSeeded', u."email",
        json_build_object(
            'role', CASE u."role" WHEN 'admin' THEN 'Administrador' ELSE 'Solo lectura' END,
            'from', 'users.role = ' || u."role"
        )::text
    FROM "users" u
    WHERE u."role" IN ('admin', 'staff');

--
-- ACTION ALTER TABLE
--
ALTER TABLE "users" DROP COLUMN "role";
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "audit_logs"
    ADD CONSTRAINT "audit_logs_fk_0"
    FOREIGN KEY("actorUserId")
    REFERENCES "users"("id")
    ON DELETE SET NULL
    ON UPDATE CASCADE;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "staff_members"
    ADD CONSTRAINT "staff_members_fk_0"
    FOREIGN KEY("roleId")
    REFERENCES "staff_roles"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
ALTER TABLE ONLY "staff_members"
    ADD CONSTRAINT "staff_members_fk_1"
    FOREIGN KEY("addedByUserId")
    REFERENCES "users"("id")
    ON DELETE SET NULL
    ON UPDATE CASCADE;


--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261011064431487-permisos-personal', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261011064431487-permisos-personal', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
