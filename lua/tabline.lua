-- Pill-style buffer tabline (editor-style "tabs").
--
-- Buffers are rendered as fully-rounded pills using glyph edges plus highlight
-- groups. Colors come from `core.ui`, so the bar follows the active theme.

local ui = require("core.ui")
local icons = require("core.icons")

local M = {
  state = { buffers = {} },
}

local defaults = {
  glyphs = {
    left = icons.ui.pill_left,
    right = icons.ui.pill_right,
    ellipsis = icons.ui.ellipsis,
    modified = icons.file.modified,
    folder = icons.file.folder,
    clock = icons.ui.clock,
    project = icons.ui.home,
  },
  max_name_len = 18,
  padding = 1, -- horizontal padding inside the main pill
  badge_padding = 0, -- horizontal padding inside the index badge
}

local function config() return M._config or defaults end

-- ---------------------------------------------------------------------------
-- Highlights
-- ---------------------------------------------------------------------------

local function setup_highlights()
  local p = ui.palette()
  local hl = vim.api.nvim_set_hl

  local active_bg = p.panel_soft
  local inactive_bg = p.panel
  local active_fg = ui.contrast(active_bg)
  local status_bg = p.panel
  local clock_bg = p.panel_alt

  local active_badge_bg = ui.blend(p.accent, active_bg, 0.35)
  local inactive_badge_bg = ui.blend(p.accent, inactive_bg, 0.20)

  -- Themes that declare `neon_glow` push the active pill's accent further, the
  -- terminal-safe stand-in for the original's bloom.
  if p.glow then
    active_badge_bg = ui.blend(p.glow_accent, active_bg, 0.45)
    active_fg = ui.contrast(active_bg, p.bg, p.glow_accent)
  end

  -- The bar itself is see-through; only the pills are painted.
  hl(0, "TabLine", { bg = "NONE", fg = p.muted })
  hl(0, "TabLineFill", { bg = "NONE", fg = p.muted })
  hl(0, "TabLineSel", { bg = "NONE", fg = p.fg })

  -- Active pill (edges sit on the transparent background, so they read round).
  hl(0, "TabLinePillActiveLeft", { fg = active_bg, bg = "NONE" })
  hl(0, "TabLinePillActiveText", { fg = active_fg, bg = active_bg, bold = true })
  hl(0, "TabLinePillActiveRight", { fg = active_bg, bg = "NONE" })
  hl(0, "TabLinePillActiveBadgeLeft", { fg = active_badge_bg, bg = active_bg })
  hl(0, "TabLinePillActiveBadgeText", { fg = p.accent, bg = active_badge_bg, bold = true })
  hl(0, "TabLinePillActiveBadgeRight", { fg = active_badge_bg, bg = active_bg })
  hl(0, "TabLinePillActiveMod", { fg = p.yellow, bg = active_bg, bold = true })

  -- Inactive pill: muted but still legible.
  hl(0, "TabLinePillInactiveLeft", { fg = inactive_bg, bg = "NONE" })
  hl(0, "TabLinePillInactiveText", { fg = p.muted, bg = inactive_bg })
  hl(0, "TabLinePillInactiveRight", { fg = inactive_bg, bg = "NONE" })
  hl(0, "TabLinePillInactiveBadgeLeft", { fg = inactive_badge_bg, bg = inactive_bg })
  hl(0, "TabLinePillInactiveBadgeText", { fg = p.muted, bg = inactive_badge_bg })
  hl(0, "TabLinePillInactiveBadgeRight", { fg = inactive_badge_bg, bg = inactive_bg })
  hl(0, "TabLinePillInactiveMod", { fg = p.orange, bg = inactive_bg })

  -- Right-hand utility pills mirror the statusline's segmented look.
  hl(0, "TabLinePillStatusLeft", { fg = status_bg, bg = "NONE" })
  hl(0, "TabLinePillStatusText", { fg = ui.contrast(status_bg), bg = status_bg, bold = true })
  hl(0, "TabLinePillStatusRight", { fg = status_bg, bg = "NONE" })

  hl(0, "TabLinePillClockLeft", { fg = clock_bg, bg = "NONE" })
  hl(0, "TabLinePillClockText", { fg = ui.contrast(clock_bg), bg = clock_bg, bold = true })
  hl(0, "TabLinePillClockIcon", { fg = p.accent, bg = clock_bg, bold = true })
  hl(0, "TabLinePillClockRight", { fg = clock_bg, bg = "NONE" })
end

-- ---------------------------------------------------------------------------
-- Rendering
-- ---------------------------------------------------------------------------

--- Shorten a filename, keeping its extension visible.
---
--- Measured and cut in characters rather than bytes. `#name` counts bytes, so
--- a name with an accent, an emoji or any CJK in it was both judged too long
--- too early and then sliced part-way through a codepoint — which reaches the
--- tabline as a replacement glyph.
---@param name string
---@param max_len integer
---@param ellipsis string
---@return string
local function truncate_name(name, max_len, ellipsis)
  if vim.fn.strdisplaywidth(name) <= max_len then
    return name
  end

  local base, ext = name:match("^(.+)%.([^%.]+)$")
  if base and ext then
    local room = max_len - vim.fn.strdisplaywidth(ext) - 2
    if room > 0 then
      return vim.fn.strcharpart(base, 0, room) .. ellipsis .. "." .. ext
    end
  end

  return vim.fn.strcharpart(name, 0, max_len - 1) .. ellipsis
end

local function pill_segment(left_hl, text_hl, right_hl, left_glyph, right_glyph, text)
  return string.format("%%#%s#%s%%#%s#%s%%#%s#%s", left_hl, left_glyph, text_hl, text, right_hl, right_glyph)
end

local function badge_segment(cfg, index, is_active)
  local pad = string.rep(" ", cfg.badge_padding)
  local prefix = is_active and "TabLinePillActiveBadge" or "TabLinePillInactiveBadge"

  return pill_segment(
    prefix .. "Left",
    prefix .. "Text",
    prefix .. "Right",
    cfg.glyphs.left,
    cfg.glyphs.right,
    pad .. tostring(index) .. pad
  )
end

local function file_icon(name)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return ""
  end

  local icon = devicons.get_icon(name, name:match("%.([^.]+)$"), { default = true })
  return type(icon) == "string" and icon or ""
end

local function buffer_pill(cfg, bufnr, index, is_current)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  if name == "" then
    name = "[No Name]"
  end

  local icon = file_icon(name)
  if icon ~= "" then
    icon = icon .. " "
  end
  name = truncate_name(name, cfg.max_name_len, cfg.glyphs.ellipsis)

  local modified = vim.bo[bufnr].modified
  local pad = string.rep(" ", cfg.padding)
  local badge = badge_segment(cfg, index, is_current)
  local prefix = is_current and "TabLinePillActive" or "TabLinePillInactive"
  local modified_mark = modified
      and string.format("%%#%sMod# %s%%#%sText#", prefix, cfg.glyphs.modified, prefix)
    or ""

  local text = pad
    .. icon
    .. name
    .. pad
    .. badge
    .. string.format("%%#%sText#", prefix)
    .. modified_mark
    .. pad

  -- `%<n>@fn@ ... %X` makes the pill clickable (left = focus, middle = close).
  return string.format("%%%d@v:lua.TablineOnClick@", bufnr)
    .. pill_segment(
      prefix .. "Left",
      prefix .. "Text",
      prefix .. "Right",
      cfg.glyphs.left,
      cfg.glyphs.right,
      text
    )
    .. "%X"
end

local function status_pills(cfg)
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local filetype = vim.bo.filetype
  local status_icon = filetype == "alpha" and cfg.glyphs.project or cfg.glyphs.folder

  local icon_pill = pill_segment(
    "TabLinePillStatusLeft",
    "TabLinePillStatusText",
    "TabLinePillStatusRight",
    cfg.glyphs.left,
    cfg.glyphs.right,
    " " .. status_icon .. " "
  )

  local clock_pill = pill_segment(
    "TabLinePillClockLeft",
    "TabLinePillClockText",
    "TabLinePillClockRight",
    cfg.glyphs.left,
    cfg.glyphs.right,
    " %#TabLinePillClockIcon#" .. cfg.glyphs.clock .. "%#TabLinePillClockText# " .. os.date("%H:%M") .. " "
  )

  return icon_pill .. "%#TabLineFill# " .. cwd .. "  " .. clock_pill
end

--- Handles clicks on a buffer pill (see the `%@` item above).
---@param bufnr integer
---@param _clicks integer
---@param button string "l", "m" or "r"
function _G.TablineOnClick(bufnr, _clicks, button)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if button == "m" then
    require("core.utils").safe_bufdelete(bufnr, false)
  else
    vim.api.nvim_set_current_buf(bufnr)
  end
end

function _G.CustomBufferTabline()
  local cfg = config()
  local current = vim.api.nvim_get_current_buf()

  local buffers = vim.tbl_filter(
    function(buf) return vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) end,
    vim.api.nvim_list_bufs()
  )

  -- Stable ordering for <A-1>..<A-9> and <C-Tab>.
  M.state.buffers = buffers

  local parts = {}
  for index, bufnr in ipairs(buffers) do
    parts[#parts + 1] = buffer_pill(cfg, bufnr, index, bufnr == current)
    parts[#parts + 1] = "%#TabLineFill# "
  end

  parts[#parts + 1] = "%#TabLineFill#%="
  parts[#parts + 1] = status_pills(cfg)

  return table.concat(parts)
end

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------

local function current_index()
  local current = vim.api.nvim_get_current_buf()
  for index, buf in ipairs(M.state.buffers or {}) do
    if buf == current then
      return index
    end
  end
end

function M.go_to(index)
  local buf = (M.state.buffers or {})[index]
  if buf and vim.api.nvim_buf_is_loaded(buf) then
    vim.api.nvim_set_current_buf(buf)
  end
end

function M.next()
  local count = #(M.state.buffers or {})
  if count == 0 then
    return
  end

  M.go_to(((current_index() or 1) % count) + 1)
end

function M.prev()
  local count = #(M.state.buffers or {})
  if count == 0 then
    return
  end

  local index = (current_index() or 1) - 1
  M.go_to(index < 1 and count or index)
end

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

local function close_current(force)
  require("core.utils").safe_bufdelete(vim.api.nvim_get_current_buf(), force)
end

--- Redraw at most once a minute, since the clock only shows HH:MM.
local function start_clock()
  if M._timer then
    pcall(function()
      M._timer:stop()
      M._timer:close()
    end)
  end

  local last = os.date("%H:%M")
  M._timer = vim.uv.new_timer()
  M._timer:start(
    15000,
    15000,
    vim.schedule_wrap(function()
      local now = os.date("%H:%M")
      if now ~= last then
        last = now
        vim.cmd("redrawtabline")
      end
    end)
  )
end

function M.setup(opts)
  M._config = vim.tbl_deep_extend("force", {}, defaults, opts or {})

  setup_highlights()
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.CustomBufferTabline()"

  local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true }) end

  map("<C-Tab>", M.next, "Next tab")
  map("<C-S-Tab>", M.prev, "Previous tab")
  map("<C-t>", "<cmd>enew<cr>", "New tab (buffer)")
  map("<A-w>", function() close_current(false) end, "Close tab (buffer)")
  map("<C-S-w>", function() close_current(false) end, "Close tab (buffer)")
  map(
    "<A-S-w>",
    function() require("core.utils").close_other_buffers(false) end,
    "Close other tabs"
  )

  for index = 1, 9 do
    map("<A-" .. index .. ">", function() M.go_to(index) end, "Go to tab " .. index)
  end

  local group = ui.create_augroup("CustomTabline")
  vim.api.nvim_create_autocmd({ "BufEnter", "BufDelete", "BufWipeout", "BufModifiedSet", "TabEnter" }, {
    group = group,
    callback = function() vim.cmd("redrawtabline") end,
  })

  ui.on_theme_change(group, function()
    setup_highlights()
    vim.cmd("redrawtabline")
  end)

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if M._timer then
        pcall(function()
          M._timer:stop()
          M._timer:close()
        end)
        M._timer = nil
      end
    end,
  })

  start_clock()
end

return M
