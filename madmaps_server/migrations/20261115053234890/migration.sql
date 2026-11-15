BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ar_capture" (
    "id" bigserial PRIMARY KEY,
    "captureId" text NOT NULL,
    "graphId" text NOT NULL,
    "graphVersion" bigint NOT NULL,
    "floorNumber" bigint NOT NULL,
    "anchorMapJson" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "ar_capture_public_idx" ON "ar_capture" USING btree ("captureId");
CREATE INDEX "ar_capture_graph_idx" ON "ar_capture" USING btree ("graphId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "floor_connector" (
    "id" bigserial PRIMARY KEY,
    "connectorId" text NOT NULL,
    "buildingId" text NOT NULL,
    "label" text NOT NULL,
    "fromGraphId" text NOT NULL,
    "fromFloor" bigint NOT NULL,
    "fromNodeId" text NOT NULL,
    "toGraphId" text NOT NULL,
    "toFloor" bigint NOT NULL,
    "toNodeId" text NOT NULL,
    "type" text NOT NULL,
    "seconds" double precision NOT NULL,
    "bidirectional" boolean NOT NULL DEFAULT true,
    "active" boolean NOT NULL DEFAULT true
);

-- Indexes
CREATE UNIQUE INDEX "floor_connector_public_idx" ON "floor_connector" USING btree ("connectorId");


--
-- MIGRATION VERSION FOR madmaps
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('madmaps', '20261115053234890', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261115053234890', "timestamp" = now();

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
