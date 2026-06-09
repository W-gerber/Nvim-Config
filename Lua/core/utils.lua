-- Shared utility functions used across the config.
-- Avoids duplicating logic in init.lua, tabline.lua, etc.

local M = {}
local uv = vim.uv or vim.loop

local function normalize_path(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  if vim.fs and type(vim.fs.normalize) == "function" then
    return vim.fs.normalize(path)
  end

  return path:gsub("\\", "/")
end

local function is_dir(path)
  path = normalize_path(path)
  if not path then
    return false
  end

  local stat = uv and uv.fs_stat and uv.fs_stat(path)
  if stat then
    return stat.type == "directory"
  end

  return vim.fn.isdirectory(path) == 1
end

local function first_existing(paths, fallback)
  for _, path in ipairs(paths) do
    path = normalize_path(path)
    if is_dir(path) then
      return path
    end
  end

  return normalize_path(fallback)
end

local function compact_paths(...)
  local paths = {}

  for index = 1, select("#", ...) do
    local path = normalize_path(select(index, ...))
    if path then
      paths[#paths + 1] = path
    end
  end

  return paths
end

local function home_dir()
  local home = normalize_path(vim.env.USERPROFILE)
    or normalize_path(vim.env.HOME)

  if home then
    return home
  end

  if uv and type(uv.os_homedir) == "function" then
    return normalize_path(uv.os_homedir())
  end

  return normalize_path(vim.fn.expand("~")) or "."
end

--- Safely close a buffer, moving windows to an alternate buffer first.
---@param bufnr number
---@param force? boolean
function M.safe_bufdelete(bufnr, force)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local windows = vim.fn.win_findbuf(bufnr)
  for _, win in ipairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      local alt = vim.fn.bufnr("#")
      if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted then
        pcall(vim.api.nvim_win_set_buf, win, alt)
      else
        local scratch = vim.api.nvim_create_buf(true, false)
        pcall(vim.api.nvim_win_set_buf, win, scratch)
      end
    end
  end

  local ok = pcall(vim.api.nvim_buf_delete, bufnr, { force = force or false })
  if not ok then
    vim.notify("Could not close buffer (unsaved changes?)", vim.log.levels.WARN)
  end
end

-- User home / Desktop / Everything paths (portable).
M.home = home_dir()

local desktop_default = normalize_path(M.home .. "/Desktop")
local desktop_onedrive = normalize_path((vim.env.OneDrive or vim.env.ONEDRIVE or "") .. "/Desktop")
local desktop_onedrive_business = normalize_path((vim.env.OneDriveCommercial or "") .. "/Desktop")
local desktop_onedrive_personal = normalize_path((vim.env.OneDriveConsumer or "") .. "/Desktop")

M.desktop = first_existing(compact_paths(
  vim.env.NVIM_DESKTOP_DIR,
  desktop_default,
  desktop_onedrive,
  desktop_onedrive_business,
  desktop_onedrive_personal
), M.home)
M.desktop_label = M.desktop == M.home and "Home" or "Desktop"

local everything_default = normalize_path(M.desktop .. "/Everything")
M.everything = first_existing(compact_paths(vim.env.NVIM_EVERYTHING_DIR, everything_default, M.desktop), M.home)
M.everything_label = M.everything == everything_default and "Everything" or "Search Root"

return M
