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
CREATE TABLE "building" (
    "id" bigserial PRIMARY KEY,
    "building_id" text NOT NULL,
    "name" text NOT NULL,
    "address" text,
    "created_by" text NOT NULL,
    "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" timestamp without time zone,
    "status" text NOT NULL DEFAULT 'active'::text,
    "version" bigint NOT NULL DEFAULT 1
);

-- Indexes
CREATE UNIQUE INDEX "building__building_id__unique_idx" ON "building" USING btree ("building_id");
CREATE INDEX "buildings_name_idx" ON "building" USING btree ("name");
CREATE INDEX "buildings_owner_idx" ON "building" USING btree ("created_by");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "edge" ADD COLUMN "edge_id" text;
ALTER TABLE "edge" ADD COLUMN "graph_id" bigint;
ALTER TABLE "edge" ADD COLUMN "created_by" text;
ALTER TABLE "edge" ADD COLUMN "updated_by" text;
ALTER TABLE "edge" ADD COLUMN "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "edge" ADD COLUMN "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "edge" ADD COLUMN "deleted_at" timestamp without time zone;
ALTER TABLE "edge" ADD COLUMN "version" bigint NOT NULL DEFAULT 1;
UPDATE "edge" SET "type" = 'walk'
WHERE "type" NOT IN ('walk', 'stairs', 'elevator', 'escalator', 'ramp');
UPDATE "edge" SET "status" = 'active'
WHERE "status" NOT IN ('active', 'deleted');
ALTER TABLE "edge" ALTER COLUMN "type" SET DEFAULT 'walk'::text;
ALTER TABLE "edge" ALTER COLUMN "status" SET DEFAULT 'active'::text;
CREATE UNIQUE INDEX "edge__edge_id__unique_idx" ON "edge" USING btree ("edge_id");
CREATE INDEX "edges_graph_idx" ON "edge" USING btree ("graph_id");
CREATE INDEX "edges_from_node_idx" ON "edge" USING btree ("from_node_id");
CREATE INDEX "edges_to_node_idx" ON "edge" USING btree ("to_node_id");
CREATE INDEX "edges_owner_idx" ON "edge" USING btree ("created_by");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "floor" (
    "id" bigserial PRIMARY KEY,
    "floor_id" text NOT NULL,
    "building_id" bigint NOT NULL,
    "floor_number" bigint NOT NULL,
    "name" text,
    "width" double precision NOT NULL,
    "height" double precision NOT NULL,
    "meters_per_unit" double precision NOT NULL DEFAULT 1.0,
    "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "floor__building_id__floor_id__unique_idx" ON "floor" USING btree ("building_id", "floor_id");
CREATE UNIQUE INDEX "floors_building_number_idx" ON "floor" USING btree ("building_id", "floor_number");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "locations" ADD COLUMN "graph_id" bigint;
ALTER TABLE "locations" ADD COLUMN "floor_id" bigint;
ALTER TABLE "locations" ADD COLUMN "status" text NOT NULL DEFAULT 'active'::text;
ALTER TABLE "locations" ADD COLUMN "created_by" text;
ALTER TABLE "locations" ADD COLUMN "updated_by" text;
ALTER TABLE "locations" ADD COLUMN "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "locations" ADD COLUMN "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "locations" ADD COLUMN "deleted_at" timestamp without time zone;
ALTER TABLE "locations" ADD COLUMN "version" bigint NOT NULL DEFAULT 1;
UPDATE "locations" SET "category" = CASE
    WHEN "category" IN ('restroom', 'bathroom', 'toilet', 'washroom') THEN 'bathroom'
    WHEN "category" IN ('cafe', 'food') THEN 'food'
    WHEN "category" IN (
        'studySpace', 'exit', 'entrance', 'elevator', 'stairs', 'classroom',
        'auditorium', 'office', 'accessibilityService', 'landmark', 'other'
    ) THEN "category"
    WHEN "category" IS NULL THEN NULL
    ELSE 'other'
END;
CREATE INDEX "locations_graph_floor_idx" ON "locations" USING btree ("graph_id", "floor_id");
CREATE INDEX "locations_room_idx" ON "locations" USING btree ("room_number");
CREATE INDEX "locations_category_idx" ON "locations" USING btree ("category");
CREATE INDEX "locations_owner_idx" ON "locations" USING btree ("created_by");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "map_graph" (
    "id" bigserial PRIMARY KEY,
    "graph_id" text NOT NULL,
    "building_id" bigint NOT NULL,
    "name" text NOT NULL,
    "owner_id" text NOT NULL,
    "status" text NOT NULL DEFAULT 'active'::text,
    "version" bigint NOT NULL DEFAULT 1,
    "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "map_graph__graph_id__unique_idx" ON "map_graph" USING btree ("graph_id");
CREATE INDEX "map_graph_building_idx" ON "map_graph" USING btree ("building_id");
CREATE INDEX "map_graph_owner_idx" ON "map_graph" USING btree ("owner_id");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "map_report" (
    "id" bigserial PRIMARY KEY,
    "report_id" text NOT NULL,
    "target_type" text NOT NULL,
    "target_id" text NOT NULL,
    "reporter_id" text NOT NULL,
    "reason" text NOT NULL,
    "notes" text,
    "status" text NOT NULL DEFAULT 'open'::text,
    "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "map_report__report_id__unique_idx" ON "map_report" USING btree ("report_id");
CREATE INDEX "reports_target_idx" ON "map_report" USING btree ("target_type", "target_id");
CREATE INDEX "reports_reporter_idx" ON "map_report" USING btree ("reporter_id");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "nodes" ADD COLUMN "graph_id" bigint;
ALTER TABLE "nodes" ADD COLUMN "floor_id" bigint;
ALTER TABLE "nodes" ADD COLUMN "created_by" text;
ALTER TABLE "nodes" ADD COLUMN "updated_by" text;
ALTER TABLE "nodes" ADD COLUMN "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "nodes" ADD COLUMN "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "nodes" ADD COLUMN "deleted_at" timestamp without time zone;
ALTER TABLE "nodes" ADD COLUMN "version" bigint NOT NULL DEFAULT 1;
UPDATE "nodes" SET "status" = 'active'
WHERE "status" NOT IN ('active', 'deleted');
ALTER TABLE "nodes" ALTER COLUMN "status" SET DEFAULT 'active'::text;
CREATE INDEX "nodes_graph_floor_idx" ON "nodes" USING btree ("graph_id", "floor_id");
CREATE INDEX "nodes_owner_idx" ON "nodes" USING btree ("created_by");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_anonymous_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_apple_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_apple_account_identifier" ON "serverpod_auth_idp_apple_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_email" ON "serverpod_auth_idp_email_account" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account_otp_login_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "completeChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_otp_login_request_email" ON "serverpod_auth_idp_email_account_otp_login_request" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account_password_reset_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_email_account_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_request_email" ON "serverpod_auth_idp_email_account_request" USING btree ("email");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_facebook_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "fullName" text,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_facebook_account_user_identifier" ON "serverpod_auth_idp_facebook_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_firebase_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text,
    "phone" text,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_firebase_account_user_identifier" ON "serverpod_auth_idp_firebase_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_github_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_github_account_user_identifier" ON "serverpod_auth_idp_github_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_google_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_google_account_user_identifier" ON "serverpod_auth_idp_google_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_microsoft_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_microsoft_account_user_identifier" ON "serverpod_auth_idp_microsoft_account" USING btree ("userIdentifier");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_passkey_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_passkey_account_key_id_base64" ON "serverpod_auth_idp_passkey_account" USING btree ("keyIdBase64");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_passkey_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "challenge" bytea NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_rate_limited_request_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "domain" text NOT NULL,
    "source" text NOT NULL,
    "key" text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);

-- Indexes
CREATE INDEX "serverpod_auth_idp_rate_limited_request_attempt_composite" ON "serverpod_auth_idp_rate_limited_request_attempt" USING btree ("domain", "source", "key", "attemptedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_idp_secret_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "challengeCodeHash" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_jwt_refresh_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    "method" text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "serverpod_auth_core_jwt_refresh_token_last_updated_at" ON "serverpod_auth_core_jwt_refresh_token" USING btree ("lastUpdatedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "imageId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_profile_user_profile_email_auth_user_id" ON "serverpod_auth_core_profile" USING btree ("authUserId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_profile_image" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "url" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_session" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    "method" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "serverpod_auth_core_user" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "edge"
    ADD CONSTRAINT "edge_fk_0"
    FOREIGN KEY("graph_id")
    REFERENCES "map_graph"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "floor"
    ADD CONSTRAINT "floor_fk_0"
    FOREIGN KEY("building_id")
    REFERENCES "building"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "locations"
    ADD CONSTRAINT "locations_fk_0"
    FOREIGN KEY("graph_id")
    REFERENCES "map_graph"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "locations"
    ADD CONSTRAINT "locations_fk_1"
    FOREIGN KEY("floor_id")
    REFERENCES "floor"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "map_graph"
    ADD CONSTRAINT "map_graph_fk_0"
    FOREIGN KEY("building_id")
    REFERENCES "building"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "nodes"
    ADD CONSTRAINT "nodes_fk_0"
    FOREIGN KEY("graph_id")
    REFERENCES "map_graph"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "nodes"
    ADD CONSTRAINT "nodes_fk_1"
    FOREIGN KEY("floor_id")
    REFERENCES "floor"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_anonymous_account"
    ADD CONSTRAINT "serverpod_auth_idp_anonymous_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_apple_account"
    ADD CONSTRAINT "serverpod_auth_idp_apple_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_otp_login_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_otp_login_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_otp_login_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_otp_login_request_fk_1"
    FOREIGN KEY("completeChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_0"
    FOREIGN KEY("emailAccountId")
    REFERENCES "serverpod_auth_idp_email_account"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_1"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_2"
    FOREIGN KEY("setPasswordChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_1"
    FOREIGN KEY("createAccountChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_facebook_account"
    ADD CONSTRAINT "serverpod_auth_idp_facebook_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_firebase_account"
    ADD CONSTRAINT "serverpod_auth_idp_firebase_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_github_account"
    ADD CONSTRAINT "serverpod_auth_idp_github_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_google_account"
    ADD CONSTRAINT "serverpod_auth_idp_google_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_microsoft_account"
    ADD CONSTRAINT "serverpod_auth_idp_microsoft_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_idp_passkey_account"
    ADD CONSTRAINT "serverpod_auth_idp_passkey_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_jwt_refresh_token"
    ADD CONSTRAINT "serverpod_auth_core_jwt_refresh_token_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_profile_image"
    ADD CONSTRAINT "serverpod_auth_core_profile_image_fk_0"
    FOREIGN KEY("userProfileId")
    REFERENCES "serverpod_auth_core_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "serverpod_auth_core_session"
    ADD CONSTRAINT "serverpod_auth_core_session_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR madmaps
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('madmaps', '20261115005518541', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261115005518541', "timestamp" = now();

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
