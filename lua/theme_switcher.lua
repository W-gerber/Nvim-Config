-- Theme switching: applies a theme, remembers the choice, and exposes a picker.
--
-- Two kinds of theme are supported (see theme_switcher/themes.lua):
--   * base46 themes  — highlights are compiled and loaded by base46
--   * colorschemes   — ordinary plugins applied with :colorscheme
--
-- Both paths end the same way: set 'background', load the theme, apply its
-- terminal palette, announce `User ThemeSwitched` so the rest of the UI can
-- restyle itself, and persist the choice.

local M = {}

local state = require("core.state")
local registry = require("theme_switcher.themes")

local DEFAULT_THEME = "neon_vommit"

-- ---------------------------------------------------------------------------
-- Registry
-- ---------------------------------------------------------------------------

local function theme_def(theme_id) return registry.get_by_id(theme_id) end

local function default_theme()
  local ok, nvconfig = pcall(require, "nvconfig")
  return (ok and nvconfig.base46 and nvconfig.base46.theme) or DEFAULT_THEME
end

--- Currently active theme id.
---@return string
function M.current_id() return vim.g.current_theme or default_theme() end

--- Every known theme id (used for command completion).
---@return string[]
function M.list()
  return vim.tbl_map(function(theme) return theme.id end, registry.get_all())
end

-- ---------------------------------------------------------------------------
-- Persistence
-- ---------------------------------------------------------------------------

--- Remember the selected theme across sessions.
---@param theme_id string
function M.save(theme_id) state.set("theme", theme_id) end

--- The theme selected in a previous session, if any.
---@return string|nil
function M.load_saved()
  local saved = state.get("theme")
  return type(saved) == "string" and saved or nil
end

-- ---------------------------------------------------------------------------
-- Applying
-- ---------------------------------------------------------------------------

-- Resolving a theme id to its table lives in core.ui, which needs the same
-- lookup for `theme_bg()` and `ui_palette` overrides.
local theme_module = require("core.ui").theme_module

-- Standard base16 → ANSI slot order, the same mapping base46 uses.
local ANSI_FROM_BASE16 = {
  [0] = "base01",
  [1] = "base08",
  [2] = "base0B",
  [3] = "base0A",
  [4] = "base0D",
  [5] = "base0E",
  [6] = "base0C",
  [7] = "base05",
  [8] = "base03",
  [9] = "base08",
  [10] = "base0B",
  [11] = "base0A",
  [12] = "base0D",
  [13] = "base0E",
  [14] = "base0C",
  [15] = "base07",
}

--- Apply a theme's ANSI palette to `:terminal` windows.
---
--- A theme that knows its real ANSI colors declares a `terminal` table and that
--- wins. Otherwise the palette is derived from base_16 the conventional way.
---
--- Deriving rather than returning early matters: `vim.g.terminal_color_*` are
--- globals that nothing resets, so skipping a theme would leave the *previous*
--- theme's terminal colors in place.
---@param module table|nil
local function apply_terminal_colors(module)
  if type(module) ~= "table" then
    return
  end

  local declared = type(module.terminal) == "table" and module.terminal or nil
  local base16 = type(module.base_16) == "table" and module.base_16 or {}

  for index = 0, 15 do
    local color = declared and declared[index] or base16[ANSI_FROM_BASE16[index]]
    if type(color) == "string" then
      vim.g["terminal_color_" .. index] = color
    end
  end
end

--- Load a theme's highlights. Runs inside the scheduled/lazyredraw section.
---@param theme_id string
---@param def table|nil
---@return boolean ok
local function load_theme(theme_id, def)
  -- Set 'background' first: themes with light/dark variants (catppuccin,
  -- onedarkpro, ...) read it when they load, and would otherwise inherit
  -- whatever the previously selected theme left behind.
  vim.o.background = (def and def.background) or "dark"

  if def and def.kind == "colorscheme" then
    -- Plain colorscheme plugin — base46 must not paint over it.
    pcall(function() require("nvconfig").base46.transparency = false end)

    if not pcall(vim.cmd.colorscheme, theme_id) then
      vim.notify("Colorscheme not found: " .. theme_id, vim.log.levels.WARN)
      return false
    end

    return true
  end

  local ok_nvconfig, nvconfig = pcall(require, "nvconfig")
  if not ok_nvconfig then
    vim.notify("nvconfig is unavailable; cannot load base46 themes", vim.log.levels.ERROR)
    return false
  end

  local module = theme_module(theme_id)
  if not module then
    vim.notify("Theme not found: " .. theme_id, vim.log.levels.WARN)
    return false
  end

  -- Wipe existing highlights first. base46 only writes the groups it knows
  -- about, so a group defined by one theme's `polish_hl` and by nothing in the
  -- next theme would survive the switch — which is how SynthWave's red `@type`
  -- ended up bleeding into tokyonight. Everything this config draws is
  -- re-applied from the `User ThemeSwitched` handlers below.
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  nvconfig.base46.theme = theme_id
  -- base46's own transparency is for themes that ship a see-through design.
  -- The editor-wide glass toggle is separate and lives in core.transparency.
  nvconfig.base46.transparency = false

  local ok_base46, base46 = pcall(require, "base46")
  if not ok_base46 then
    vim.notify("base46 is not available: " .. tostring(base46), vim.log.levels.ERROR)
    return false
  end

  -- Some base46 themes also ship a matching :colorscheme; harmless if absent.
  pcall(vim.cmd.colorscheme, theme_id)

  local ok_load, err = pcall(base46.load_all_highlights)
  if not ok_load then
    vim.notify(("Failed to load theme %s: %s"):format(theme_id, err), vim.log.levels.ERROR)
    return false
  end

  apply_terminal_colors(module)

  return true
end

--- Apply the glass-background default this theme prefers, unless the user has
--- already made an explicit choice.
---@param def table|nil
local function apply_glass_preference(def)
  if state.get("glass") ~= nil then
    return -- user chose; respect it across every theme
  end

  local wanted = def and def.glass
  if wanted == nil then
    return
  end

  vim.g.ui_transparent = wanted
end

-- Applying a theme is deferred, so two of them can be in flight at once — which
-- is the normal case, not an edge one: every keystroke in the picker fires an
-- `apply`. Two pieces of state make that safe.
--
-- `generation` is bumped per request, and a scheduled pass that finds itself
-- superseded returns without doing the work. Loading a theme rewrites every
-- highlight group in the editor; running that once per keypress while someone
-- holds a cursor key is most of what made the picker feel heavy, and only the
-- last one was ever visible anyway.
--
-- `saved_lazyredraw` holds the user's real setting across the whole burst.
-- Capturing it per call was a bug with an unpleasant signature: the second
-- `apply` captured `true` — the value the *first* one had just set — and
-- restored that, leaving 'lazyredraw' stuck on for the rest of the session.
-- With redraws suppressed, other windows kept painting their old contents, so
-- switching themes with a split or the file explorer open appeared to restyle
-- only the focused window. It did not self-correct: every later switch captured
-- `true` again.
local generation = 0
local saved_lazyredraw = nil

--- Apply a theme.
---@param theme_id string
---@param opts? { persist?: boolean, preview?: boolean }
function M.apply(theme_id, opts)
  opts = opts or {}
  local persist = opts.persist ~= false
  local preview = opts.preview == true

  local def = theme_def(theme_id)
  vim.g.current_theme = theme_id

  generation = generation + 1
  local token = generation

  -- Only the first request in a burst records the real value.
  if saved_lazyredraw == nil then
    saved_lazyredraw = vim.o.lazyredraw
  end
  vim.o.lazyredraw = true

  vim.schedule(function()
    -- Superseded: a newer request is already queued and will restore state.
    if token ~= generation then
      return
    end

    local ok = false

    -- pcall so a theme that throws mid-load still gets 'lazyredraw' back;
    -- leaving it on is what turns one bad theme into a dead-looking editor.
    pcall(function()
      apply_glass_preference(def)
      ok = load_theme(theme_id, def)

      -- Let the rest of the UI (statusline, tabline, floats) restyle itself.
      vim.api.nvim_exec_autocmds("User", { pattern = "ThemeSwitched" })
    end)

    vim.o.lazyredraw = saved_lazyredraw or false
    saved_lazyredraw = nil

    if ok and persist then
      M.save(theme_id)
    end

    -- Every window has to be told to repaint, not just the focused one:
    -- rewriting a highlight group does not by itself dirty the windows that
    -- render with it. Previews redraw too — they are the *only* thing drawing
    -- the preview — but skip the lualine rebuild, which is the expensive half.
    if not preview then
      pcall(function() require("lualine").refresh() end)
    end
    pcall(vim.cmd.redraw)
  end)
end

--- Re-apply the theme saved in a previous session.
function M.apply_saved() M.apply(M.load_saved() or default_theme(), { persist = false }) end

--- Open the Telescope-based theme picker.
function M.open_picker()
  local ok, picker = pcall(require, "theme_switcher.picker")
  if not ok or type(picker.open) ~= "function" then
    vim.notify("Theme picker is not available (is Telescope installed?)", vim.log.levels.ERROR)
    return
  end

  picker.open()
end

function M.setup()
  pcall(M.apply_saved)

  vim.keymap.set("n", "<leader>th", M.open_picker, { desc = "Theme picker", silent = true })

  vim.api.nvim_create_user_command("Theme", function(opts)
    if opts.args == "" then
      M.open_picker()
      return
    end

    if not theme_def(opts.args) then
      vim.notify("Unknown theme: " .. opts.args, vim.log.levels.WARN)
      return
    end

    M.apply(opts.args)
  end, {
    nargs = "?",
    complete = M.list,
    desc = "Switch theme (no argument opens the picker)",
  })
end

return M
