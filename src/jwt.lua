local cjson = require "cjson"
local openssl_digest = require "resty.openssl.digest"
local openssl_hmac = require "resty.openssl.hmac"
local openssl_pkey = require "resty.openssl.pkey"
local asn_sequence = require "kong.plugins.jwt.asn_sequence"

local encode_base64 = ngx.encode_base64
local concat = table.concat

local function load_credential(jwt_secret_key)
  local row, err = kong.db.jwt_secrets:select_by_key(jwt_secret_key)
  if err then
    return nil, err
  end
  return row
end

--- base 64 encoding
-- @param input String to base64 encode
-- @return Base64 encoded string
local function base64_encode(input)
  local result = encode_base64(input, true)
  result = result:gsub("+", "-"):gsub("/", "_")
  return result
end

--- Supported algorithms for signing tokens.
local alg_sign = {
  HS256 = function(data, key) return openssl_hmac.new(key, "sha256"):final(data) end,
  HS384 = function(data, key) return openssl_hmac.new(key, "sha384"):final(data) end,
  HS512 = function(data, key) return openssl_hmac.new(key, "sha512"):final(data) end,
  RS256 = function(data, key)
    local digest = openssl_digest.new("sha256")
    assert(digest:update(data))
    return assert(openssl_pkey.new(key):sign(digest))
  end,
  RS512 = function(data, key)
    local digest = openssl_digest.new("sha512")
    assert(digest:update(data))
    return assert(openssl_pkey.new(key):sign(digest))
  end,
  ES256 = function(data, key)
    local pkey = openssl_pkey.new(key)
    local digest = openssl_digest.new("sha256")
    assert(digest:update(data))
    local signature = assert(pkey:sign(digest))

    local derSequence = asn_sequence.parse_simple_sequence(signature)
    local r = asn_sequence.unsign_integer(derSequence[1], 32)
    local s = asn_sequence.unsign_integer(derSequence[2], 32)
    assert(#r == 32)
    assert(#s == 32)
    return r .. s
  end
}

local function encode_token(data, key, alg, header)
  if type(data) ~= "table" then
    error("Argument #1 must be table", 2)
  end

  if type(key) ~= "string" then
    error("Argument #2 must be string", 2)
  end

  if header and type(header) ~= "table" then
    error("Argument #4 must be a table", 2)
  end

  alg = alg or "HS256"

  if not alg_sign[alg] then
    error("Algorithm not supported", 2)
  end

  local header = header or { typ = "JWT", alg = alg }
  local segments = {
    base64_encode(cjson.encode(header)),
    base64_encode(cjson.encode(data))
  }

  local signing_input = concat(segments, ".")
  local signature = alg_sign[alg](signing_input, key)

  segments[#segments+1] = base64_encode(signature)

  return concat(segments, ".")
end

return {
  load_credential = load_credential,
  encode_token = encode_token
}