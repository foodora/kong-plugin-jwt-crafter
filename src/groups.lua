local tablex = require "pl.tablex"


local EMPTY = tablex.readonly {}


local kong = kong
local type = type
local mt_cache = { __mode = "k" }
local setmetatable = setmetatable
local consumer_groups_cache = setmetatable({}, mt_cache)
local consumer_in_groups_cache = setmetatable({}, mt_cache)
local table_insert = table.insert


local function load_groups_into_memory(consumer_pk)
  local groups = {}
  local len    = 0

  for row, err in kong.db.acls:each_for_consumer(consumer_pk) do
    if err then
      return nil, err
    end
    len = len + 1
    groups[len] = row
  end

  return groups
end

--- Returns the database records with groups the consumer belongs to
-- @param consumer_id (string) the consumer for which to fetch the groups it belongs to
-- @return table with group records (empty table if none), or nil+error
local function get_consumer_groups_raw(consumer_id)
  local cache_key = kong.db.acls:cache_key(consumer_id)
  local raw_groups, err = kong.cache:get(cache_key, nil,
                                         load_groups_into_memory,
                                         { id = consumer_id })
  if err then
    return nil, err
  end

  -- use EMPTY to be able to use it as a cache key, since a new table would
  -- immediately be collected again and not allow for negative caching.
  return raw_groups or EMPTY
end


--- Returns a table as list with all groups associated to the consumer's JWT credentials
-- The table will have an array part to iterate over, and a hash part
--
-- If there are no groups defined, it will return an empty table
-- @param consumer_id (string) the consumer for which to fetch the groups it belongs to
-- @return table with groups (empty table if none) or nil+error
local function get_consumer_groups(consumer_id)
  local raw_groups, err = get_consumer_groups_raw(consumer_id)
  if not raw_groups then
    return nil, err
  end

  local groups = consumer_groups_cache[raw_groups]
  if not groups then
    groups = {}
    consumer_groups_cache[raw_groups] = groups
    for i = 1, #raw_groups do
      local group = raw_groups[i].group
      table_insert(groups, group)
    end
  end
  return groups
end

return {
  get_consumer_groups = get_consumer_groups
}