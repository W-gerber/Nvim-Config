local M = {}

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and type(hl) == "table" then
    return hl
  end

  return {}
end

local function to_hex(value)
  if type(value) == "number" then
    return string.format("#%06x", value)
  end

  if type(value) == "string" and value ~= "" then
    return value
  end
end

local function parse_hex(hex)
  if type(hex) ~= "string" then
    return
  end

  local value = hex:gsub("#", "")
  if #value ~= 6 then
    return
  end

  local r = tonumber(value:sub(1, 2), 16)
  local g = tonumber(value:sub(3, 4), 16)
  local b = tonumber(value:sub(5, 6), 16)
  if not r or not g or not b then
    return
  end

  return r, g, b
end

local function blend_hex(foreground, background, alpha)
  local fr, fg, fb = parse_hex(foreground)
  local br, bg, bb = parse_hex(background)
  if not fr or not br then
    return foreground or background
  end

  alpha = math.max(0, math.min(1, alpha or 0.5))

  local function blend_channel(fg_channel, bg_channel)
    return math.floor((fg_channel * alpha) + (bg_channel * (1 - alpha)) + 0.5)
  end

  return string.format(
    "#%02x%02x%02x",
    blend_channel(fr, br),
    blend_channel(fg, bg),
    blend_channel(fb, bb)
  )
end

function M.create_augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

function M.on_theme_change(group, callback)
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      vim.schedule(callback)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "ThemeSwitched",
    callback = function()
      vim.schedule(callback)
    end,
  })
end

function M.float_palette()
  local is_dark = vim.o.background ~= "light"
  local current_theme = tostring(vim.g.current_theme or "")
  local normal = get_hl("Normal")
  local normal_float = get_hl("NormalFloat")
  local float_border = get_hl("FloatBorder")
  local title = get_hl("Title")
  local comment = get_hl("Comment")
  local visual = get_hl("Visual")
  local diagnostic_info = get_hl("DiagnosticInfo")
  local diagnostic_hint = get_hl("DiagnosticHint")
  local diagnostic_warn = get_hl("DiagnosticWarn")
  local diagnostic_error = get_hl("DiagnosticError")

  local ok_theme, theme = pcall(require, "theme")
  local neon = ok_theme and theme and theme.neon or {}
  local use_neon_palette = current_theme == "neon_commit"

  return {
    bg = to_hex(normal_float.bg) or to_hex(normal.bg) or (is_dark and "#10141d" or "#f8fafc"),
    fg = to_hex(normal_float.fg) or to_hex(normal.fg) or (is_dark and "#e5e7eb" or "#0f172a"),
    border = (use_neon_palette and neon.cyan) or to_hex(float_border.fg) or to_hex(comment.fg) or (is_dark and "#64748b" or "#94a3b8"),
    accent = (use_neon_palette and neon.cyan) or to_hex(title.fg) or to_hex(diagnostic_info.fg) or (is_dark and "#7dd3fc" or "#2563eb"),
    secondary = (use_neon_palette and neon.hotpink) or to_hex(diagnostic_hint.fg) or (is_dark and "#f472b6" or "#db2777"),
    success = (use_neon_palette and neon.lime) or (is_dark and "#86efac" or "#16a34a"),
    warning = (use_neon_palette and neon.orange) or to_hex(diagnostic_warn.fg) or (is_dark and "#fbbf24" or "#d97706"),
    error = to_hex(diagnostic_error.fg) or (is_dark and "#f87171" or "#dc2626"),
    muted = to_hex(comment.fg) or (is_dark and "#94a3b8" or "#64748b"),
    selection_bg = to_hex(visual.bg) or (is_dark and "#1f2937" or "#dbeafe"),
    selection_fg = to_hex(visual.fg) or to_hex(normal_float.fg) or to_hex(normal.fg) or (is_dark and "#f8fafc" or "#0f172a"),
  }
end

function M.utility_palette()
  local base = M.float_palette()
  local is_dark = vim.o.background ~= "light"
  local accent = is_dark and "#3c5f8a" or "#1f3b63"
  local secondary = is_dark and "#55769e" or "#365882"
  local tertiary = is_dark and "#6c89ad" or "#56769d"

  return {
    bg = blend_hex(accent, base.bg, is_dark and 0.14 or 0.05) or base.bg,
    panel = blend_hex(accent, base.bg, is_dark and 0.18 or 0.09) or base.bg,
    panel_alt = blend_hex(accent, base.bg, is_dark and 0.26 or 0.14) or base.bg,
    border = blend_hex(accent, base.border, is_dark and 0.48 or 0.30) or base.border,
    accent = accent,
    secondary = secondary,
    tertiary = tertiary,
    fg = base.fg,
    muted = blend_hex(accent, base.muted, is_dark and 0.25 or 0.12) or base.muted,
    selection_bg = blend_hex(accent, base.selection_bg, is_dark and 0.42 or 0.18) or base.selection_bg,
    selection_fg = base.selection_fg,
    title_fg = "#f8fafc",
  }
end

return M