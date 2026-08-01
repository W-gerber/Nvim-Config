-- Small persisted key/value store for UI preferences that should survive a
-- restart (selected theme, glass background, ...).
--
-- Kept deliberately dumb: one flat JSON object under stdpath("data"). Both the
-- theme switcher and the transparency toggle write here, which is why this
-- lives in `core` rather than inside either of them — it keeps them from having
-- to require each other.

local M = {}

local STATE_FILE = vim.fs.joinpath(vim.fn.stdpath("data"), "ui_state.json")

-- Superseded by STATE_FILE, which also holds the glass preference. Read once so
-- an existing install keeps the theme it had selected.
local LEGACY_THEME_FILE = vim.fs.joinpath(vim.fn.stdpath("data"), "theme_state.json")

---@type table|nil
local cache = nil

--- Decode a JSON state file, tolerating a missing or corrupt one.
---@param path string
---@return table|nil
local function read_json(path)
  if vim.fn.filereadable(path) == 0 then
    return nil
  end

  local ok_read, lines = pcall(vim.fn.readfile, path)
  if not ok_read or vim.tbl_isempty(lines) then
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  return (ok and type(decoded) == "table") and decoded or nil
end

--- The whole persisted state, read from disk once per session.
---@return table
function M.read()
  if cache then
    return cache
  end

  cache = read_json(STATE_FILE) or {}

  -- One-time migration: adopt the theme from the pre-`ui_state.json` layout.
  if cache.theme == nil then
    local legacy = read_json(LEGACY_THEME_FILE)
    if legacy and type(legacy.theme) == "string" then
      cache.theme = legacy.theme
    end
  end

  return cache
end

--- Read a single key.
---@param key string
---@return any
function M.get(key) return M.read()[key] end

--- Merge `patch` into the persisted state and write it back.
---@param patch table
function M.update(patch)
  local state = vim.tbl_extend("force", M.read(), patch)
  cache = state

  local ok, encoded = pcall(vim.json.encode, state)
  if not ok then
    return
  end

  pcall(vim.fn.writefile, { encoded }, STATE_FILE)
end

--- Write a single key.
---@param key string
---@param value any
function M.set(key, value) M.update({ [key] = value }) end

return M
