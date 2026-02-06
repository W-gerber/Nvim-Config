-- Custom pill-style tabline for buffers (editor-style “tabs”).
-- Renders fully-rounded pills using glyph edges and highlight groups.

local M = {
  state = {
    buffers = {},
  },
}

local defaults = {
  glyphs = {
    left = "",
    right = "",
    ellipsis = "…",
    modified = "●",
    folder = "",
    -- Clock glyph to match the screenshot style
    clock = "",
    -- Small left status icon pill (project/user)
    project = "",
  },
  max_name_len = 18,
  padding = 1, -- horizontal padding inside the main pill
  badge_padding = 0, -- horizontal padding inside the badge pill
  shade = {
    inactive_bg = 0.70, -- < 1 = darker, > 1 = lighter
    badge_bg = 0.85,
  },
  colors = {
    -- These are used as overrides. When nil, we pull from `theme.neon`.
    active_bg = nil,
    inactive_bg = nil,
    status_bg = nil,
    text_on_accent = nil,
    text_muted = nil,
    badge_fg_active = nil,
    badge_fg_inactive = nil,
    bg = nil,

    -- Status pill background should match the statusline “mode bubble”.
    -- Defaults mirror `Lua/statusline.lua`.
    status_by_mode = {
      n = "#ff2d95", -- normal (hotpink)
      i = "#CFFF04", -- insert (neon_yellow)
      v = "#00BCE3", -- visual (cyan)
      V = "#00BCE3",
      ["\22"] = "#00BCE3", -- visual block (CTRL-V)
      R = "#ff5189", -- replace (red)
      c = "#ff2d95", -- command
    },
  },
}

local function merge_config(user)
  return vim.tbl_deep_extend("force", {}, defaults, user or {})
end

local function get_palette(cfg)
  local ok, theme = pcall(require, "theme")
  local neon = (ok and theme and theme.neon) or {
    cyan = "#00d7ff",
    hotpink = "#ff2d95",
    lime = "#b7ff3a",
    purple = "#9d7cff",
    orange = "#ff9e1b",
    white = "#ffffff",
    bg = "#080808",
  }

  return {
    active_bg = cfg.colors.active_bg or neon.hotpink,
    inactive_base = neon.purple,
    status_bg = cfg.colors.status_bg or neon.cyan,
    bg = cfg.colors.bg or neon.bg or "#080808",
    text_on_accent = cfg.colors.text_on_accent or (neon.bg or "#080808"),
    text_muted = cfg.colors.text_muted or neon.white,
    badge_fg_active = cfg.colors.badge_fg_active or neon.lime,
    badge_fg_inactive = cfg.colors.badge_fg_inactive or neon.cyan,
    orange = neon.orange,
  }
end

local function current_mode_key()
  local m = vim.api.nvim_get_mode().mode
  return m:sub(1, 1)
end

local function status_bg_for_mode(cfg)
  local key = current_mode_key()
  return (cfg.colors.status_by_mode and cfg.colors.status_by_mode[key]) or cfg.colors.status_bg
end

local function clamp_byte(v)
  if v < 0 then
    return 0
  end
  if v > 255 then
    return 255
  end
  return v
end

local function shade_hex(hex, factor)
  if type(hex) ~= "string" then
    return hex
  end
  local h = hex:gsub("#", "")
  if #h ~= 6 then
    return hex
  end
  local r = tonumber(h:sub(1, 2), 16)
  local g = tonumber(h:sub(3, 4), 16)
  local b = tonumber(h:sub(5, 6), 16)
  if not r or not g or not b then
    return hex
  end
  r = clamp_byte(math.floor(r * factor + 0.5))
  g = clamp_byte(math.floor(g * factor + 0.5))
  b = clamp_byte(math.floor(b * factor + 0.5))
  return string.format("#%02x%02x%02x", r, g, b)
end

local function setup_highlights(cfg)
  local p = get_palette(cfg)
  local hl = vim.api.nvim_set_hl

  -- Status area uses two pills like the screenshot:
  -- - left project icon pill uses statusline mode color
  -- - right clock pill uses statusline mode color
  local mode_bg = status_bg_for_mode(cfg) or p.status_bg

  local inactive_bg = cfg.colors.inactive_bg or shade_hex(p.inactive_base, cfg.shade.inactive_bg)
  local active_bg = p.active_bg
  local active_badge_bg = shade_hex(active_bg, cfg.shade.badge_bg)
  local inactive_badge_bg = shade_hex(inactive_bg, cfg.shade.badge_bg)
  local status_badge_bg = shade_hex(mode_bg, cfg.shade.badge_bg)
  local clock_badge_bg = shade_hex(mode_bg, cfg.shade.badge_bg)

  -- Base
  hl(0, "TabLine", { bg = "NONE", fg = p.text_muted })
  hl(0, "TabLineFill", { bg = "NONE" })

  -- Active pill: “floating” (edges on NONE background)
  hl(0, "TabLinePillActiveLeft", { fg = active_bg, bg = "NONE" })
  hl(0, "TabLinePillActiveText", { fg = p.text_on_accent, bg = active_bg, bold = true })
  hl(0, "TabLinePillActiveRight", { fg = active_bg, bg = "NONE" })

  -- Active badge: nested mini-pill inside active pill
  hl(0, "TabLinePillActiveBadgeLeft", { fg = active_badge_bg, bg = active_bg })
  hl(0, "TabLinePillActiveBadgeText", { fg = p.badge_fg_active, bg = active_badge_bg, bold = true })
  hl(0, "TabLinePillActiveBadgeRight", { fg = active_badge_bg, bg = active_bg })
  hl(0, "TabLinePillActiveMod", { fg = p.badge_fg_active, bg = active_bg, bold = true })

  -- Inactive pill: muted but readable
  hl(0, "TabLinePillInactiveLeft", { fg = inactive_bg, bg = "NONE" })
  hl(0, "TabLinePillInactiveText", { fg = p.text_muted, bg = inactive_bg })
  hl(0, "TabLinePillInactiveRight", { fg = inactive_bg, bg = "NONE" })

  -- Inactive badge
  hl(0, "TabLinePillInactiveBadgeLeft", { fg = inactive_badge_bg, bg = inactive_bg })
  hl(0, "TabLinePillInactiveBadgeText", { fg = p.badge_fg_inactive, bg = inactive_badge_bg })
  hl(0, "TabLinePillInactiveBadgeRight", { fg = inactive_badge_bg, bg = inactive_bg })
  hl(0, "TabLinePillInactiveMod", { fg = p.orange, bg = inactive_bg })

  -- Status pill (left icon pill) uses statusline mode color
  hl(0, "TabLinePillStatusLeft", { fg = mode_bg, bg = "NONE" })
  hl(0, "TabLinePillStatusText", { fg = p.text_on_accent, bg = mode_bg, bold = true })
  hl(0, "TabLinePillStatusRight", { fg = mode_bg, bg = "NONE" })

  -- Clock pill (right) matches statusline mode color
  hl(0, "TabLinePillClockLeft", { fg = mode_bg, bg = "NONE" })
  hl(0, "TabLinePillClockText", { fg = p.text_on_accent, bg = mode_bg, bold = true })
  hl(0, "TabLinePillClockRight", { fg = mode_bg, bg = "NONE" })

  -- Optional nested badge tones (kept for consistency)
  hl(0, "TabLinePillStatusBadgeLeft", { fg = status_badge_bg, bg = mode_bg })
  hl(0, "TabLinePillStatusBadgeText", { fg = p.text_on_accent, bg = status_badge_bg, bold = true })
  hl(0, "TabLinePillStatusBadgeRight", { fg = status_badge_bg, bg = mode_bg })

  hl(0, "TabLinePillClockBadgeLeft", { fg = clock_badge_bg, bg = mode_bg })
  hl(0, "TabLinePillClockBadgeText", { fg = p.text_on_accent, bg = clock_badge_bg, bold = true })
  hl(0, "TabLinePillClockBadgeRight", { fg = clock_badge_bg, bg = mode_bg })
end

-- Truncate filename intelligently
local function truncate_name(name, max_len)
  if #name <= max_len then
    return name
  end
  -- Keep extension visible
  local base, ext = name:match("^(.+)%.([^%.]+)$")
  if base and ext then
    local needed = max_len - #ext - 2
    if needed > 0 then
      return base:sub(1, needed) .. defaults.glyphs.ellipsis .. "." .. ext
    end
  end
  return name:sub(1, max_len - 1) .. defaults.glyphs.ellipsis
end

local function pill_segment(left_hl, text_hl, right_hl, left_glyph, right_glyph, text)
  return string.format("%%#%s#%s%%#%s#%s%%#%s#%s", left_hl, left_glyph, text_hl, text, right_hl, right_glyph)
end

local function badge_segment(cfg, idx, is_active)
  local pad = string.rep(" ", cfg.badge_padding)
  local left_g = cfg.glyphs.left
  local right_g = cfg.glyphs.right

  if is_active then
    return pill_segment(
      "TabLinePillActiveBadgeLeft",
      "TabLinePillActiveBadgeText",
      "TabLinePillActiveBadgeRight",
      left_g,
      right_g,
      pad .. tostring(idx) .. pad
    )
  end

  return pill_segment(
    "TabLinePillInactiveBadgeLeft",
    "TabLinePillInactiveBadgeText",
    "TabLinePillInactiveBadgeRight",
    left_g,
    right_g,
    pad .. tostring(idx) .. pad
  )
end

local function file_icon(name)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return ""
  end

  local ext = name:match("%.([^.]+)$")
  local icon = devicons.get_icon(name, ext, { default = true })
  if type(icon) == "string" and icon ~= "" then
    return icon
  end
  return ""
end

-- Build a single buffer pill (with nested badge mini-pill)
local function buffer_pill(cfg, bufnr, idx, is_current)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
  if name == "" then
    name = "[No Name]"
  end
  local icon = file_icon(name)
  if icon ~= "" then
    icon = icon .. " "
  end
  name = truncate_name(name, cfg.max_name_len)

  local modified = vim.api.nvim_get_option_value("modified", { buf = bufnr })
  local pad = string.rep(" ", cfg.padding)
  local left_g = cfg.glyphs.left
  local right_g = cfg.glyphs.right
  local badge = badge_segment(cfg, idx, is_current)
  local mod = modified and (" " .. cfg.glyphs.modified) or ""

  if is_current then
    -- Make the badge read as the last colored element of the pill
    local text = pad .. icon .. name .. pad .. badge .. "%#TabLinePillActiveText#" .. mod .. pad
    return pill_segment("TabLinePillActiveLeft", "TabLinePillActiveText", "TabLinePillActiveRight", left_g, right_g, text)
  end

  local text = pad
    .. icon
    .. name
    .. pad
    .. badge
    .. "%#TabLinePillInactiveText#"
    .. (modified and ("%#TabLinePillInactiveMod#" .. mod .. "%#TabLinePillInactiveText#") or "")
    .. pad
  return pill_segment("TabLinePillInactiveLeft", "TabLinePillInactiveText", "TabLinePillInactiveRight", left_g, right_g, text)
end

local function status_pills(cfg)
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local time = os.date("%H:%M")
  local left_g = cfg.glyphs.left
  local right_g = cfg.glyphs.right

  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
  local status_icon = (ft == "alpha") and cfg.glyphs.project or cfg.glyphs.folder

  -- Small left icon pill + plain text label + separate clock pill
  local icon_pill = pill_segment(
    "TabLinePillStatusLeft",
    "TabLinePillStatusText",
    "TabLinePillStatusRight",
    left_g,
    right_g,
    " " .. status_icon .. " "
  )

  local clock_pill = pill_segment(
    "TabLinePillClockLeft",
    "TabLinePillClockText",
    "TabLinePillClockRight",
    left_g,
    right_g,
    " " .. cfg.glyphs.clock .. " " .. time .. " "
  )

  return icon_pill .. "%#TabLineFill# " .. cwd .. "  " .. clock_pill
end

-- Main tabline function
function _G.CustomBufferTabline()
  local s = ""
  local current_buf = vim.api.nvim_get_current_buf()

  -- Get all listed buffers
  local buffers = vim.tbl_filter(function(b)
    return vim.api.nvim_get_option_value("buflisted", { buf = b }) and vim.api.nvim_buf_is_loaded(b)
  end, vim.api.nvim_list_bufs())

  -- Keep a stable mapping for Alt+1..9 and Ctrl+Tab navigation.
  M.state.buffers = buffers

  -- Build buffer pills
  local cfg = M._config or defaults

  -- Make the right-side pill match the statusline “mode bubble” color.
  -- This is cheap enough and guarantees it stays in sync when mode changes.
  setup_highlights(cfg)
  for i, bufnr in ipairs(buffers) do
    local is_current = (bufnr == current_buf)
    s = s .. buffer_pill(cfg, bufnr, i, is_current)
    s = s .. "%#TabLineFill# "
  end

  -- Right-align status pill
  s = s .. "%#TabLineFill#%="
  s = s .. status_pills(cfg)

  return s
end

local function current_index()
  local cur = vim.api.nvim_get_current_buf()
  for i, b in ipairs(M.state.buffers or {}) do
    if b == cur then
      return i
    end
  end
  return nil
end

function M.go_to(index)
  local b = (M.state.buffers or {})[index]
  if b and vim.api.nvim_buf_is_loaded(b) then
    vim.api.nvim_set_current_buf(b)
  end
end

function M.next()
  local buffers = M.state.buffers or {}
  if #buffers == 0 then
    return
  end
  local i = current_index() or 1
  local next_i = (i % #buffers) + 1
  M.go_to(next_i)
end

function M.prev()
  local buffers = M.state.buffers or {}
  if #buffers == 0 then
    return
  end
  local i = current_index() or 1
  local prev_i = i - 1
  if prev_i < 1 then
    prev_i = #buffers
  end
  M.go_to(prev_i)
end

local function safe_bufdelete(bufnr, force)
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

  pcall(vim.api.nvim_buf_delete, bufnr, { force = force or false })
end

-- Setup function
function M.setup(opts)
  M._config = merge_config(opts)
  setup_highlights(M._config)
  vim.o.showtabline = 2 -- Always show tabline
  vim.o.tabline = "%!v:lua.CustomBufferTabline()"
  vim.o.winbar = ""

  -- Required keybindings
  vim.keymap.set("n", "<C-Tab>", M.next, { desc = "Next tab", silent = true })
  vim.keymap.set("n", "<C-S-Tab>", M.prev, { desc = "Previous tab", silent = true })
  for i = 1, 9 do
    vim.keymap.set("n", "<A-" .. i .. ">", function()
      M.go_to(i)
    end, { desc = "Go to tab " .. i, silent = true })
  end

  -- Practical buffer actions ("tabs" in this UI)
  vim.keymap.set("n", "<A-w>", function()
    safe_bufdelete(vim.api.nvim_get_current_buf(), false)
  end, { desc = "Close tab (buffer)", silent = true })

  vim.keymap.set("n", "<C-S-w>", function()
    safe_bufdelete(vim.api.nvim_get_current_buf(), false)
  end, { desc = "Close tab (buffer)", silent = true })

  vim.keymap.set("n", "<A-S-w>", function()
    local current = vim.api.nvim_get_current_buf()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= current and vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
        safe_bufdelete(b, false)
      end
    end
  end, { desc = "Close other tabs", silent = true })
  vim.keymap.set("n", "<C-t>", ":enew<CR>", { desc = "New tab (buffer)", silent = true })

  -- Refresh tabline on buffer events and time updates (for clock)
  local group = vim.api.nvim_create_augroup("CustomTabline", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufDelete", "BufWipeout", "TabEnter" }, {
    group = group,
    callback = function()
      vim.cmd("redrawtabline")
    end,
  })

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = group,
    callback = function()
      setup_highlights(M._config or defaults)
      vim.cmd("redrawtabline")
    end,
  })

  -- Update time every 10 seconds
  if M._timer then
    pcall(function()
      M._timer:stop()
      M._timer:close()
    end)
    M._timer = nil
  end

  M._timer = vim.loop.new_timer()
  M._timer:start(10000, 10000, vim.schedule_wrap(function()
    vim.cmd("redrawtabline")
  end))
end

return M
