local function load_totp_token(consumer_id)
  local row, err = kong.db.jwt_crafter_totp_token:select_by_consumer_uniq(consumer_id)
  if err then
    return nil, err
  end
  return row['totp_token']
end

return {
  load_totp_token = load_totp_token
}