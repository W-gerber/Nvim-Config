-- Shared UI/color layer.
--
-- Everything that draws chrome (statusline, tabline, floats, pickers) pulls its
-- colors from `M.palette()` instead of hard-coding hex values. The palette is
-- derived from the *active* colorscheme's highlight groups, so switching themes
-- restyles the whole UI instead of leaving neon pills on a pastel theme.

local M = {}

-- ---------------------------------------------------------------------------
-- Hex helpers
-- ---------------------------------------------------------------------------

--- Normalize a highlight color (24-bit number or "#rrggbb") to "#rrggbb".
---@param value string|number|nil
---@return string|nil
function M.hex(value)
  if type(value) == "number" then
    return string.format("#%06x", value)
  end

  if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
    return value
  end
end

local function rgb(hex)
  hex = M.hex(hex)
  if not hex then
    return
  end

  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function clamp_byte(value) return math.max(0, math.min(255, math.floor(value + 0.5))) end

--- Mix `foreground` into `background` by `alpha` (0 = background, 1 = foreground).
---@param foreground string|nil
---@param background string|nil
---@param alpha number
---@return string
function M.blend(foreground, background, alpha)
  local fr, fg, fb = rgb(foreground)
  local br, bg, bb = rgb(background)
  if not fr or not br then
    return M.hex(foreground) or M.hex(background) or "#000000"
  end

  alpha = math.max(0, math.min(1, alpha or 0.5))

  return string.format(
    "#%02x%02x%02x",
    clamp_byte(fr * alpha + br * (1 - alpha)),
    clamp_byte(fg * alpha + bg * (1 - alpha)),
    clamp_byte(fb * alpha + bb * (1 - alpha))
  )
end

--- Perceived brightness, 0-255.
---@param hex string|nil
---@return number
function M.luminance(hex)
  local r, g, b = rgb(hex)
  if not r then
    return 0
  end

  return (r * 299 + g * 587 + b * 114) / 1000
end

--- Pick a readable foreground for the given background.
---@param background string|nil
---@param dark? string
---@param light? string
---@return string
function M.contrast(background, dark, light)
  return M.luminance(background) >= 150 and (dark or "#0b0f18") or (light or "#ffffff")
end

-- ---------------------------------------------------------------------------
-- Highlight lookup
-- ---------------------------------------------------------------------------

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  return (ok and type(hl) == "table") and hl or {}
end

--- First defined `fg` among the given highlight groups.
local function fg_of(groups, fallback)
  for _, name in ipairs(groups) do
    local color = M.hex(get_hl(name).fg)
    if color then
      return color
    end
  end

  return fallback
end

--- First defined `bg` among the given highlight groups.
local function bg_of(groups, fallback)
  for _, name in ipairs(groups) do
    local color = M.hex(get_hl(name).bg)
    if color then
      return color
    end
  end

  return fallback
end

-- ---------------------------------------------------------------------------
-- Base background
-- ---------------------------------------------------------------------------
--
-- The "glass" look blanks `Normal.bg`, which would leave the palette with
-- nothing to blend surfaces against. `remember_base_bg()` is called by the
-- transparency handler *before* the background is cleared so we keep the
-- theme's real backdrop around for shading.

local base_bg = nil

--- Resolve a theme id to its base46 theme table.
---
--- Two namespaces can define a theme: `lua/themes/<id>.lua` here, and base46's
--- own `base46.themes.<id>`. The local one wins — but only if it is a *complete*
--- theme. A local module carrying only partial overrides (no `base_16`) is not
--- a theme, it is a patch meant for `nvconfig.changed_themes`; returning one
--- would report a theme with no colors at all.
---@param id string|nil defaults to the active theme
---@return table|nil
function M.theme_module(id)
  id = id or vim.g.current_theme
  if type(id) ~= "string" or id == "" then
    return nil
  end

  local fallback

  for _, name in ipairs({ "themes." .. id, "base46.themes." .. id }) do
    local ok, theme = pcall(require, name)
    if ok and type(theme) == "table" then
      if type(theme.base_16) == "table" and next(theme.base_16) ~= nil then
        return theme
      end
      fallback = fallback or theme
    end
  end

  return fallback
end

--- The background the active base46 theme *declares*, read from its module.
---
--- Needed because `Normal.bg` is not a reliable source once glass has blanked
--- it: asking the theme directly is the only way to get the real backdrop back
--- when turning glass off again.
---@return string|nil
function M.theme_bg()
  local theme = M.theme_module()
  if not theme then
    return nil
  end

  return M.hex(theme.base_16 and theme.base_16.base00) or M.hex(theme.base_30 and theme.base_30.black)
end

--- Record the colorscheme's true background (called before transparency is
--- applied). Falls back to the theme's declared background, then to the last
--- known good value — never overwrites a usable backdrop with nil.
---@return string|nil
function M.remember_base_bg()
  base_bg = M.hex(get_hl("Normal").bg) or M.theme_bg() or base_bg
  return base_bg
end

--- The backdrop that chrome is drawn against, tried in three steps:
---
---  1. the theme's live `Normal.bg`, when it sets one;
---  2. the value `remember_base_bg()` captured before glass blanked it, which
---     keeps panel shading tied to the theme rather than to the terminal;
---  3. plain black/white, when neither exists.
---
--- Deliberately *not* guessed from other highlight groups: this config rewrites
--- several of them itself, so doing that would feed the palette its own output.
---@return string
function M.base_bg() return M.hex(get_hl("Normal").bg) or base_bg or (M.is_dark() and "#000000" or "#ffffff") end

--- A "frosted glass" surface: the theme's background lifted toward white, or
--- pressed toward black on light themes.
---
--- Deliberately *not* accent-tinted the way `palette.panel` is. A pill the size
--- of a word can borrow the accent and look deliberate; a panel-sized sheet
--- borrowing it reads as colored film over whatever is behind it — obvious on
--- themes with a vivid accent, where a translucent popup turns lime or magenta.
--- Panels that cover content (which-key, the cmdline, picker rows) use this;
--- the statusline and tabline pills keep their tint.
---@param level? number 0-1 opacity of the lift, defaults to 0.08
---@return string
function M.frost(level)
  return M.blend(M.is_dark() and "#ffffff" or "#000000", M.base_bg(), level or 0.08)
end

--- Background for a popup pane: nothing at all while the glass preference is
--- on, a frosted surface otherwise.
---
--- Neovim cannot frost a *terminal's* backdrop. `winblend` composites a float
--- against the editor cells beneath it, and where those have no background it
--- falls back to the default one — so a blended pane over a transparent editor
--- comes out as a dark sheet, which is exactly the thing an acrylic or blurred
--- terminal is already doing properly one layer down. The only way to let that
--- effect through is to draw no background at all and let the panel read from
--- its rim, its title and its text.
---@param level? number frost level used when the editor is not transparent
---@return string
function M.pane_bg(level)
  return vim.g.ui_transparent and "NONE" or M.frost(level)
end

--- True when the active theme is a dark one (falls back to foreground brightness).
---@return boolean
function M.is_dark()
  local bg = M.hex(get_hl("Normal").bg) or base_bg
  if bg then
    return M.luminance(bg) < 128
  end

  if vim.o.background == "light" then
    return false
  end

  local fg = M.hex(get_hl("Normal").fg)
  return fg == nil or M.luminance(fg) >= 128
end

-- ---------------------------------------------------------------------------
-- Palette
-- ---------------------------------------------------------------------------

local cached = nil

--- Optional per-theme overrides for the derived palette.
---
--- Derivation reads semantic colors out of syntax groups, which is a heuristic:
--- it assumes `String` is greenish, `Keyword` purple-ish, and so on. That holds
--- for most themes and fails loudly for the interesting ones — SynthWave '84
--- has orange strings and yellow keywords, so "green" would come out orange.
---
--- A theme can therefore publish an exact `ui_palette` (and an optional
--- `neon_glow`) alongside its base46 tables, and those values win.
---@return table overrides, table|nil glow
local function theme_overrides()
  local module = M.theme_module()
  if not module then
    return {}, nil
  end

  local overrides = type(module.ui_palette) == "table" and module.ui_palette or {}
  local glow = type(module.neon_glow) == "table" and module.neon_glow or nil

  return overrides, glow
end

--- Semantic palette for every piece of chrome this config draws.
---
--- Surfaces (`panel`/`panel_alt`/`panel_soft`) are the theme's accent tinted
--- into its background, which keeps pill-style chrome legible on both dark and
--- light themes without per-theme tables.
---@return table
function M.palette()
  if cached then
    return cached
  end

  local dark = M.is_dark()
  local bg = M.base_bg()
  local fg = fg_of({ "Normal", "NormalFloat" }, dark and "#e5e7eb" or "#111827")
  local muted = fg_of({ "Comment", "NonText" }, M.blend(fg, bg, 0.55))

  -- Diagnostic and diff groups come first everywhere they exist: they carry the
  -- meaning we actually want (ok/warn/error, added/removed) instead of whatever
  -- hue the theme happened to give strings or keywords.
  local blue = fg_of({ "DiagnosticInfo", "Function", "Directory" }, dark and "#7dd3fc" or "#2563eb")
  local cyan = fg_of({ "DiagnosticHint", "Special", "Operator" }, blue)
  local green = fg_of({ "DiagnosticOk", "Added", "diffAdded", "String" }, dark and "#86efac" or "#16a34a")
  local yellow = fg_of({ "DiagnosticWarn", "Constant", "WarningMsg" }, dark and "#fbbf24" or "#d97706")
  local orange = fg_of({ "Number", "Boolean" }, yellow)
  local red = fg_of({ "DiagnosticError", "ErrorMsg", "Removed" }, dark and "#f87171" or "#dc2626")
  local purple = fg_of({ "Keyword", "Statement", "PreProc" }, dark and "#c4b5fd" or "#7c3aed")
  local pink = fg_of({ "Identifier", "Type" }, purple)

  -- Accent-tinted surfaces. Dark themes take a heavier tint so pills read as
  -- solid against a transparent terminal; light themes stay subtle.
  local function surface(level) return M.blend(blue, bg, (dark and 0.12 or 0.06) * level) end

  local selection_bg = bg_of({ "Visual" }, surface(2.4))

  local palette = {
    is_dark = dark,

    bg = bg,
    fg = fg,
    muted = muted,
    border = fg_of({ "FloatBorder", "WinSeparator", "Comment" }, M.blend(blue, bg, dark and 0.5 or 0.35)),

    panel = surface(1.0),
    panel_alt = surface(1.7),
    panel_soft = surface(2.4),

    accent = blue,
    blue = blue,
    cyan = cyan,
    green = green,
    yellow = yellow,
    orange = orange,
    red = red,
    purple = purple,
    pink = pink,

    selection_bg = selection_bg,
    selection_fg = fg_of({ "Visual" }, fg),
  }

  local overrides, glow = theme_overrides()
  palette = vim.tbl_extend("force", palette, overrides)

  -- Surfaces are derived from `accent`, so recompute them when a theme replaced
  -- it — otherwise a declared accent would leave the panels tinted by the old one.
  if overrides.accent and not overrides.panel then
    local function tinted(level) return M.blend(palette.accent, bg, (dark and 0.12 or 0.06) * level) end
    palette.panel = tinted(1.0)
    palette.panel_alt = tinted(1.7)
    palette.panel_soft = tinted(2.4)
  end

  -- The closest a terminal gets to SynthWave '84's bloom shader: themes that
  -- opt in get bold chrome accents instead of a glow they cannot have.
  palette.glow = glow and glow.enabled == true or false
  palette.glow_accent = (glow and glow.accent) or palette.accent
  palette.glow_secondary = (glow and glow.secondary) or palette.cyan

  -- Mode bubble colors, keyed by the first char of `nvim_get_mode().mode`.
  palette.modes = vim.tbl_extend("force", {
    n = palette.accent,
    i = palette.green,
    v = palette.purple,
    V = palette.purple,
    ["\22"] = palette.purple, -- CTRL-V
    s = palette.purple,
    S = palette.purple,
    R = palette.red,
    c = palette.yellow,
    t = palette.cyan,
  }, type(overrides.modes) == "table" and overrides.modes or {})

  cached = palette
  return cached
end

--- Drop the cached palette (called whenever highlights change).
function M.invalidate() cached = nil end

-- ---------------------------------------------------------------------------
-- Borders
-- ---------------------------------------------------------------------------

--- The beveled "glass" rim, as the `{ char, highlight }` pairs Neovim and nui
--- both take for a border.
---
--- Three groups rather than one flat outline is what gives the panels their
--- bevel: `<prefix>BorderTop` is lit, `<prefix>BorderBottom` is shadowed, and
--- `<prefix>Border` carries the sides. Callers define those three groups; this
--- only decides which cell gets which.
---
--- Order is the one Neovim documents: top-left, top, top-right, right,
--- bottom-right, bottom, bottom-left, left.
---@param prefix string highlight prefix, e.g. "WhichKey" or "NoiceCmdlinePopup"
---@return table[]
function M.glass_border(prefix)
  return {
    { "\u{256d}", prefix .. "BorderTop" }, -- ╭
    { "\u{2500}", prefix .. "BorderTop" }, -- ─
    { "\u{256e}", prefix .. "BorderTop" }, -- ╮
    { "\u{2502}", prefix .. "Border" }, -- │
    { "\u{256f}", prefix .. "BorderBottom" }, -- ╯
    { "\u{2500}", prefix .. "BorderBottom" }, -- ─
    { "\u{2570}", prefix .. "BorderBottom" }, -- ╰
    { "\u{2502}", prefix .. "Border" }, -- │
  }
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------

function M.create_augroup(name) return vim.api.nvim_create_augroup(name, { clear = true }) end

--- Run `callback` whenever the colorscheme or base46 theme changes.
---
--- Two events are watched because neither is sufficient alone: a base46 theme
--- with no matching `colors/<id>.vim` never fires `ColorScheme`, and an
--- ordinary colorscheme plugin knows nothing about `ThemeSwitched`.
---
--- The catch is that switching to a colorscheme *plugin* fires both, one tick
--- apart, so every listener used to restyle the whole UI twice — measured at
--- ~21ms of highlight writing done for nothing, and a visible double-repaint.
--- Coalescing to one run per tick fixes both: the events still arrive, but only
--- the first one queues work. `invalidate()` stays outside the guard, since
--- dropping a cache is cheap and must happen on every signal.
---@param group integer augroup id
---@param callback fun()
function M.on_theme_change(group, callback)
  local queued = false

  local function schedule()
    M.invalidate()

    if queued then
      return
    end
    queued = true

    vim.schedule(function()
      queued = false
      callback()
    end)
  end

  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = schedule })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "ThemeSwitched", callback = schedule })
end

-- Keep the palette cache honest even for listeners that never call
-- `on_theme_change` (e.g. code that reads `M.palette()` on demand).
local invalidate_group = vim.api.nvim_create_augroup("UiPaletteCache", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", { group = invalidate_group, callback = M.invalidate })
vim.api.nvim_create_autocmd("User", {
  group = invalidate_group,
  pattern = "ThemeSwitched",
  callback = M.invalidate,
})

return M
