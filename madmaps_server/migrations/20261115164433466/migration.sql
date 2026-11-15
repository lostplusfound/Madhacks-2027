BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "place_map" (
    "id" bigserial PRIMARY KEY,
    "map_id" text NOT NULL,
    "building_name" text NOT NULL,
    "floor_label" text NOT NULL,
    "map_json" text NOT NULL,
    "version" bigint NOT NULL DEFAULT 1,
    "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "place_map__map_id__unique_idx" ON "place_map" USING btree ("map_id");


--
-- MIGRATION VERSION FOR madmaps
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('madmaps', '20261115164433466', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261115164433466', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20261015164015382', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261015164015382', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
