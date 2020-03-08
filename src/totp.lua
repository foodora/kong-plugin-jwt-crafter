local otp = require "otp"

local function load_totp_key(consumer_id)
  local row, err = kong.db.jwt_crafter_totp_keys:select_by_consumer_uniq(consumer_id)
  if err then
    return nil, err
  end
  if row then
    return row['totp_key']
  end
  return nil
end

local function verify(consumer_id, timetoken)
	local key = load_totp_key(consumer_id)
	local totp = otp.new_totp_from_key(key)
	return totp:verify(timetoken)
end

return {
  verify = verify,
  load_totp_key = load_totp_key
}