return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "jwt_crafter_totp_token" (
        "id"           UUID PRIMARY KEY,
        "created_at"   TIMESTAMP WITHOUT TIME ZONE,
        "consumer_id"  UUID REFERENCES "consumers" ("id") ON DELETE CASCADE,
        "totp_token"   TEXT,
        CONSTRAINT u_consumer_id unique (consumer_id)
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
      CREATE TABLE IF NOT EXISTS jwt_crafter_totp_token (
        id          uuid PRIMARY KEY,
        created_at  timestamp,
        consumer_id uuid UNIQUE,
        totp_token  text
      );
      
      CREATE INDEX IF NOT EXISTS ON jwt_crafter_totp_token (totp_token);
      CREATE INDEX IF NOT EXISTS ON jwt_crafter_totp_token (consumer_id);
    ]],
  }
}