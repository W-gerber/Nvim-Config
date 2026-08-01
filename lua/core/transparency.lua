-- "Glass" UI: let the terminal background show through the editor surfaces.
--
-- This is a user preference, not a theme property. Two things feed the initial
-- state, in order:
--
--   1. an explicit <leader>ub / :Transparency choice, persisted in core.state
--   2. otherwise the `glass` hint on the active theme's registry entry
--
-- That ordering matters: themes whose identity *is* their background (the deep
-- violet of synthwave84, any light theme) would be ruined by glass on first
-- launch, but someone who deliberately turned it on should keep it everywhere.

local M = {}

local ui = require("core.ui")
local state = require("core.state")

-- Surfaces that become see-through. Chrome that needs to stay solid to be
-- readable (statusline pills, tabline pills, popups) is styled elsewhere.
local TRANSPARENT_GROUPS = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "FoldColumn",
  "LineNr",
  "EndOfBuffer",
  "MsgArea",
  "WinSeparator",
}

-- Groups that draw on top of *source code* rather than being chrome of their
-- own. base46 gives each of these an opaque near-black background (`one_bg3`,
-- #141414 on the neon themes). On the theme's own backdrop that is a barely
-- visible tint; over a transparent one it is a solid black rectangle sitting
-- behind an identifier — which is where "why does `classList` have a box around
-- it?" comes from.
--
-- Clearing the background outright is not the fix: every one of these is
-- carrying a signal. `LspReference*` marks the other uses of the symbol under
-- the cursor, and this config runs `vim.lsp.buf.document_highlight` on
-- CursorHold with 'updatetime' at 250ms (see plugins/lspconfig.lua), so it
-- fires a quarter-second after the cursor lands on *any* identifier — every
-- property, method, object key and parameter you rest on. Under glass the
-- signal moves onto the text as an underline, which reads the same and paints
-- nothing.
local REFERENCE_GROUPS = {
  -- vim.lsp.buf.document_highlight
  "LspReferenceText",
  "LspReferenceRead",
  "LspReferenceWrite",
  -- vim-illuminate's names for the same idea, in case it is ever added
  "IlluminatedWordText",
  "IlluminatedWordRead",
  "IlluminatedWordWrite",
}

-- The matching bracket, and the matching keyword pair (`if`/`end`). Same
-- problem, but these want to be found instantly rather than merely noticed, so
-- they get the accent rather than a dim underline.
local MATCH_GROUPS = { "MatchParen", "MatchWord" }

-- Selections and search hits are *defined* by their fill — take it away and
-- there is nothing left to see, since neither carries a foreground of its own.
-- They are exempt from the backdrop sweep below even on the themes where they
-- happen to share a color with it; a theme that does that has a contrast
-- problem the sweep would turn into an invisibility bug.
local KEEPS_ITS_FILL = {
  Visual = true,
  VisualNOS = true,
  CursorLine = true,
  CursorColumn = true,
  ColorColumn = true,
  Search = true,
  IncSearch = true,
  CurSearch = true,
  Substitute = true,
  Cursor = true,
  TermCursor = true,
  QuickFixLine = true,
}

--- Is the glass look currently enabled?
---@return boolean
function M.enabled() return vim.g.ui_transparent == true end

--- Every color that counts as "the editor's backdrop" for this theme.
---
--- A group whose background is one of these is not drawing a surface, it is
--- repeating the one already behind it — invisible before glass, a rectangle
--- after. Several candidates are collected because `Normal.bg` is unreadable
--- once glass has blanked it, and `remember_base_bg()` has nothing to remember
--- on the very first pass (it runs before any theme has loaded).
---@return table<string, true>
local function backdrop_colors()
  local candidates = {
    ui.hex(vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg),
    ui.theme_bg(),
    ui.remember_base_bg(),
  }

  -- base46 themes name their darkest surfaces in `base_30`; these are what its
  -- integrations reach for when they want "the background".
  local theme = ui.theme_module()
  if theme and type(theme.base_30) == "table" then
    for _, key in ipairs({ "black", "black2", "darker_black" }) do
      candidates[#candidates + 1] = ui.hex(theme.base_30[key])
    end
  end

  local set = {}
  for _, color in ipairs(candidates) do
    if color then
      set[color:lower()] = true
    end
  end

  return set
end

--- Drop backgrounds that only repeat the backdrop.
---
--- Deliberately a sweep rather than a list. base46 writes `bg = <the theme's
--- own background>` on a scattering of groups (`LspInlayHint`,
--- `@markup.quote`, ...) and adds more over time; enumerating them means
--- rediscovering this bug every few updates. Because the test is "this bg is
--- already what is behind it", removing it cannot change how anything looks on
--- an opaque theme — it only stops the rectangle appearing on a transparent one.
---
--- Linked groups are skipped: they have no background of their own, and
--- re-setting one would replace the link with a snapshot of whatever it
--- happened to resolve to.
local function clear_backdrop_backgrounds()
  local backdrops = backdrop_colors()
  if vim.tbl_isempty(backdrops) then
    return
  end

  for name, definition in pairs(vim.api.nvim_get_hl(0, {})) do
    local background = ui.hex(definition.bg)

    if
      not definition.link
      and not KEEPS_ITS_FILL[name]
      and background
      and backdrops[background:lower()]
    then
      definition.bg = nil
      definition.ctermbg = nil
      pcall(vim.api.nvim_set_hl, 0, name, definition)
    end
  end
end

--- Restyle the groups that paint over source code.
---
--- Under glass they lose their background entirely and say what they mean with
--- the text; otherwise they get a frosted tint, which is legible against an
--- opaque theme and still lighter than base46's near-black slab.
---@param palette table
local function style_code_overlays(palette)
  local set = vim.api.nvim_set_hl
  local glass = M.enabled()

  for _, group in ipairs(REFERENCE_GROUPS) do
    set(
      0,
      group,
      glass and { bg = "NONE", underline = true, sp = ui.blend(palette.accent, palette.bg, 0.75) }
        or { bg = ui.frost(0.14) }
    )
  end

  for _, group in ipairs(MATCH_GROUPS) do
    set(
      0,
      group,
      glass and { bg = "NONE", fg = palette.accent, bold = true, underline = true }
        or { bg = ui.frost(0.2), fg = palette.accent, bold = true }
    )
  end

  -- Inlay hints are annotations *between* tokens, so a filled background reads
  -- as a box wedged into the middle of a line. Italic and muted is enough.
  set(0, "LspInlayHint", {
    fg = ui.blend(palette.muted, palette.bg, 0.85),
    bg = glass and "NONE" or ui.frost(0.06),
    italic = true,
  })
end

local function apply()
  -- `remember_base_bg` falls back to the theme's declared background and then
  -- to the last known good value. Reading `Normal.bg` alone would return nil
  -- whenever glass is already on, so turning it back off had nothing to
  -- restore and the editor stayed transparent.
  local base = ui.remember_base_bg()
  ui.invalidate()

  local palette = ui.palette()
  local set = vim.api.nvim_set_hl

  if M.enabled() then
    -- Order matters: the sweep identifies a backdrop background by comparing it
    -- against `Normal.bg`, so it has to run before Normal is blanked.
    clear_backdrop_backgrounds()

    for _, group in ipairs(TRANSPARENT_GROUPS) do
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      hl.bg = nil
      hl.ctermbg = nil
      set(0, group, hl)
    end
  elseif base then
    set(0, "Normal", { fg = palette.fg, bg = base })
    set(0, "NormalNC", { fg = palette.fg, bg = base })
    set(0, "NormalFloat", { fg = palette.fg, bg = base })
  end

  -- Reference, match and inlay-hint highlighting draws over source code, so it
  -- is restyled whether or not glass is on — base46's near-black slab is a
  -- rectangle behind an identifier either way, just a more obvious one when the
  -- terminal shows through.
  style_code_overlays(palette)

  -- A lifted cursorline reads on both dark and light themes; a hard-coded dark
  -- value disappears entirely on anything pale. `ui.frost()` and not the
  -- accent-tinted panel: this is a band across the full width of the editor,
  -- and on a theme with a vivid accent a tinted one reads as colored film over
  -- the line you are working on.
  set(0, "CursorLine", { bg = ui.frost(0.07) })
  set(0, "CursorLineNr", { fg = palette.accent, bold = true })
end

--- Turn the glass look on/off (no argument toggles).
---
--- An explicit call is remembered, so it survives restarts and overrides the
--- per-theme `glass` hint from then on.
---@param enabled? boolean
---@param opts? { persist?: boolean, notify?: boolean }
function M.toggle(enabled, opts)
  opts = opts or {}

  if enabled == nil then
    enabled = not M.enabled()
  end

  vim.g.ui_transparent = enabled

  if opts.persist ~= false then
    state.set("glass", enabled)
  end

  -- Re-apply the colorscheme so its own backgrounds come back before we decide
  -- what to blank; otherwise turning transparency off leaves holes behind.
  local colors_name = vim.g.colors_name
  if colors_name and colors_name ~= "" then
    pcall(vim.cmd.colorscheme, colors_name)
  end

  apply()

  -- Popups decide whether to draw a background from this setting (see
  -- `ui.pane_bg()`), so every module that styles chrome has to re-run. They all
  -- listen through `ui.on_theme_change`, and firing the event here means they
  -- do not have to depend on the colorscheme reload above having happened —
  -- there is none to reload before a theme has been chosen.
  vim.api.nvim_exec_autocmds("User", { pattern = "ThemeSwitched" })

  if opts.notify ~= false then
    vim.notify("Transparency " .. (enabled and "on" or "off"), vim.log.levels.INFO)
  end
end

function M.setup()
  -- Seed from the persisted choice. When there is none, the theme's own hint
  -- takes over as each theme loads (see theme_switcher.apply_glass_preference).
  local saved = state.get("glass")
  if type(saved) == "boolean" then
    vim.g.ui_transparent = saved
  elseif vim.g.ui_transparent == nil then
    vim.g.ui_transparent = false
  end

  apply()

  local group = ui.create_augroup("GlassUI")
  ui.on_theme_change(group, apply)

  vim.api.nvim_create_user_command("Transparency", function(opts)
    local arg = opts.args
    M.toggle(arg == "" and nil or arg == "on")
  end, {
    nargs = "?",
    complete = function() return { "on", "off" } end,
    desc = "Toggle background transparency",
  })
end

return M
