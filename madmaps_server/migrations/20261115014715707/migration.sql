BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "map_wall" (
    "id" bigserial PRIMARY KEY,
    "graph_id" bigint NOT NULL,
    "wall_id" text NOT NULL,
    "floor_id" text NOT NULL,
    "vertices_json" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "map_wall_graph_wall_idx" ON "map_wall" USING btree ("graph_id", "wall_id");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "map_wall"
    ADD CONSTRAINT "map_wall_fk_0"
    FOREIGN KEY("graph_id")
    REFERENCES "map_graph"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR madmaps
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('madmaps', '20261115014715707', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261115014715707', "timestamp" = now();

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
