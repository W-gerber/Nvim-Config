-- Shared utility functions used across the config.
-- Avoids duplicating logic in init.lua, tabline.lua, etc.

local M = {}

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

--- User home / Desktop / Everything paths (portable).
M.home = vim.fn.expand("$USERPROFILE")
M.desktop = M.home .. "/Desktop"
M.everything = M.home .. "/Desktop/Everything"

return M
