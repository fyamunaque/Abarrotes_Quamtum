BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "order_promo_code_uses_redemption_idx" ON "order_promo_code_uses" USING btree ("redemptionId");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "promo_code_redemptions_user_idx" ON "promo_code_redemptions" USING btree ("userId");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "promotions_promo_code_idx" ON "promotions" USING btree ("promoCodeId");

--
-- MIGRATION VERSION FOR abarrotes
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('abarrotes', '20261104012650884-indices-de-codigos', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261104012650884-indices-de-codigos', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
