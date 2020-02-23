return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "jwt_crafter_totp_token" (
        "id"           UUID PRIMARY KEY,
        "created_at"   TIMESTAMP WITHOUT TIME ZONE,
        "consumer_id"  UUID REFERENCES "consumers" ("id") ON DELETE CASCADE,
        "consumer_uniq" TEXT UNIQUE,
        "totp_token"   TEXT,
        CONSTRAINT u_consumer_id UNIQUE (consumer_id)
      );
    
      DO $$
      BEGIN
        CREATE INDEX IF NOT EXISTS "jwt_crafter_totp_token_totp_token"
                                ON "jwt_crafter_totp_token" ("totp_token");
      EXCEPTION WHEN UNDEFINED_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
  },

  cassandra = {
    up = [[
      NOT IMPLEMENTED
    ]],
  }
}