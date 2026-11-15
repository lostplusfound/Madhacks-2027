BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "edge" (
    "id" bigserial PRIMARY KEY,
    "from_node_id" text NOT NULL,
    "to_node_id" text NOT NULL,
    "type" text NOT NULL,
    "cost_px" double precision NOT NULL,
    "bidirectional" boolean NOT NULL,
    "status" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "locations" (
    "id" bigserial PRIMARY KEY,
    "location_id" text NOT NULL,
    "floor" bigint NOT NULL,
    "room_number" text,
    "name" text,
    "category" text,
    "aliases" text,
    "route_node_id" text,
    "review_note" text
);

-- Indexes
CREATE UNIQUE INDEX "locations__location_id__unique_idx" ON "locations" USING btree ("location_id");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "nodes" (
    "id" bigserial PRIMARY KEY,
    "node_id" text NOT NULL,
    "floor" bigint NOT NULL,
    "x" double precision NOT NULL,
    "y" double precision NOT NULL,
    "location_id" text,
    "kind" text NOT NULL,
    "status" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "nodes__node_id__unique_idx" ON "nodes" USING btree ("node_id");


--
-- MIGRATION VERSION FOR madmaps
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('madmaps', '20261114233145439', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261114233145439', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
