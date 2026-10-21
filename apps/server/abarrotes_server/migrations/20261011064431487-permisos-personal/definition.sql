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
-- Class AuditLog as table audit_logs
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
-- Class Category as table categories
--
CREATE TABLE "categories" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "name" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "categories_name_idx" ON "categories" USING btree ("name");

--
-- Class DeviceToken as table device_tokens
--
CREATE TABLE "device_tokens" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "token" text NOT NULL,
    "platform" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "device_tokens_token_idx" ON "device_tokens" USING btree ("token");
CREATE INDEX "device_tokens_user_idx" ON "device_tokens" USING btree ("userId");

--
-- Class InventoryMovement as table inventory_movements
--
CREATE TABLE "inventory_movements" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "type" text NOT NULL,
    "quantity" bigint NOT NULL,
    "reason" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "productId" uuid NOT NULL,
    "userId" uuid NOT NULL
);

--
-- Class OrderItem as table order_items
--
CREATE TABLE "order_items" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "quantity" bigint NOT NULL,
    "unitPriceCents" bigint NOT NULL,
    "orderId" uuid NOT NULL,
    "productId" uuid NOT NULL
);

--
-- Class Order as table orders
--
CREATE TABLE "orders" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "status" text NOT NULL DEFAULT 'pendingConfirmation'::text,
    "totalCents" bigint NOT NULL,
    "deliveryAddress" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "customerId" uuid NOT NULL
);

--
-- Class Product as table products
--
CREATE TABLE "products" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "name" text NOT NULL,
    "description" text,
    "sku" text NOT NULL,
    "priceCents" bigint NOT NULL,
    "imageUrl" text,
    "active" boolean NOT NULL DEFAULT true,
    "currentStock" bigint NOT NULL DEFAULT 0,
    "minStock" bigint NOT NULL DEFAULT 0,
    "expirationDate" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "categoryId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "products_sku_idx" ON "products" USING btree ("sku");

--
-- Class Promotion as table promotions
--
CREATE TABLE "promotions" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "promoPriceCents" bigint NOT NULL,
    "startDate" timestamp without time zone NOT NULL,
    "endDate" timestamp without time zone NOT NULL,
    "active" boolean NOT NULL DEFAULT true,
    "productId" uuid NOT NULL,
    "audience" text NOT NULL DEFAULT 'everyone'::text,
    "title" text
);

--
-- Class StaffMember as table staff_members
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
-- Class Role as table staff_roles
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
-- Class Supply as table supplies
--
CREATE TABLE "supplies" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "name" text NOT NULL,
    "unit" text NOT NULL,
    "quantity" bigint NOT NULL DEFAULT 0,
    "minQuantity" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Class User as table users
--
CREATE TABLE "users" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "firebaseUid" text NOT NULL,
    "email" text NOT NULL,
    "emailVerified" boolean NOT NULL DEFAULT false,
    "name" text NOT NULL,
    "phone" text,
    "address" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "users_firebase_uid_idx" ON "users" USING btree ("firebaseUid");
CREATE UNIQUE INDEX "users_email_idx" ON "users" USING btree ("email");

--
-- Class VipCustomer as table vip_customers
--
CREATE TABLE "vip_customers" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "email" text NOT NULL,
    "active" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "addedByUserId" uuid NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "vip_customers_email_idx" ON "vip_customers" USING btree ("email");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectDownloadEntry as table serverpod_cloud_storage_direct_download
--
CREATE TABLE "serverpod_cloud_storage_direct_download" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "downloadFileName" text,
    "contentType" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_download_auth_key" ON "serverpod_cloud_storage_direct_download" USING btree ("authKey");
CREATE INDEX "serverpod_cloud_storage_direct_download_expiration" ON "serverpod_cloud_storage_direct_download" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "maxFileSize" bigint NOT NULL DEFAULT 10485760,
    "contentLength" bigint,
    "preventOverwrite" boolean NOT NULL DEFAULT false,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text,
    "scheduling" json
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class FutureCallClaimEntry as table serverpod_future_call_claim
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" bigserial PRIMARY KEY,
    "futureCallId" bigint,
    "lastHeartbeatTime" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" USING btree ("futureCallId");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId", "order");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" USING btree ("sessionLogId", "order");

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId", "order");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "audit_logs" table
--
ALTER TABLE ONLY "audit_logs"
    ADD CONSTRAINT "audit_logs_fk_0"
    FOREIGN KEY("actorUserId")
    REFERENCES "users"("id")
    ON DELETE SET NULL
    ON UPDATE CASCADE;

--
-- Foreign relations for "device_tokens" table
--
ALTER TABLE ONLY "device_tokens"
    ADD CONSTRAINT "device_tokens_fk_0"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;

--
-- Foreign relations for "inventory_movements" table
--
ALTER TABLE ONLY "inventory_movements"
    ADD CONSTRAINT "inventory_movements_fk_0"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
ALTER TABLE ONLY "inventory_movements"
    ADD CONSTRAINT "inventory_movements_fk_1"
    FOREIGN KEY("userId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Foreign relations for "order_items" table
--
ALTER TABLE ONLY "order_items"
    ADD CONSTRAINT "order_items_fk_0"
    FOREIGN KEY("orderId")
    REFERENCES "orders"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;
ALTER TABLE ONLY "order_items"
    ADD CONSTRAINT "order_items_fk_1"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Foreign relations for "orders" table
--
ALTER TABLE ONLY "orders"
    ADD CONSTRAINT "orders_fk_0"
    FOREIGN KEY("customerId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Foreign relations for "products" table
--
ALTER TABLE ONLY "products"
    ADD CONSTRAINT "products_fk_0"
    FOREIGN KEY("categoryId")
    REFERENCES "categories"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Foreign relations for "promotions" table
--
ALTER TABLE ONLY "promotions"
    ADD CONSTRAINT "promotions_fk_0"
    FOREIGN KEY("productId")
    REFERENCES "products"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Foreign relations for "staff_members" table
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
-- Foreign relations for "vip_customers" table
--
ALTER TABLE ONLY "vip_customers"
    ADD CONSTRAINT "vip_customers_fk_0"
    FOREIGN KEY("addedByUserId")
    REFERENCES "users"("id")
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

--
-- Foreign relations for "serverpod_future_call_claim" table
--
ALTER TABLE ONLY "serverpod_future_call_claim"
    ADD CONSTRAINT "serverpod_future_call_claim_fk_0"
    FOREIGN KEY("futureCallId")
    REFERENCES "serverpod_future_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


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
