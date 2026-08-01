-- Chrome for plugin UIs that this config does not own a spec for.
--
-- Lazy, Mason, Trouble, the quickfix window, diff mode, floats and the built-in
-- pop-up menu all ship their own highlight groups. Left alone they inherit
-- whatever the colorscheme happens to define, which is where "everything else
-- is cohesive but :Lazy looks like a different program" comes from.
--
-- Everything here derives from `core.ui.palette()` and re-applies on theme
-- change, so it stays consistent with the statusline, tabline and pickers.

local M = {}

local ui = require("core.ui")

--- Highlight groups keyed by name, rebuilt from the palette on every call.
---@param p table palette
---@return table<string, vim.api.keyset.highlight>
local function groups(p)
  local on_panel = ui.contrast(p.panel, p.bg, p.fg)
  local accent = p.glow and p.glow_accent or p.accent

  -- Menus and chips that cover the buffer follow `ui.pane_bg()`: transparent
  -- while the glass preference is on, a neutral frost otherwise. The tinted
  -- `panel` colors stay on chrome that sits in its own window (Lazy, Mason).
  local menu = ui.pane_bg(0.1)

  return {
    -- Floating windows -----------------------------------------------------
    FloatTitle = { fg = accent, bold = true },
    FloatFooter = { fg = p.muted },

    -- Built-in completion / pop-up menu (used by cmdline, `:set wildmenu`) ---
    Pmenu = { fg = p.fg, bg = menu },
    PmenuSel = { fg = p.selection_fg, bg = p.selection_bg, bold = true },
    PmenuSbar = { bg = ui.pane_bg(0.14) },
    PmenuThumb = { bg = accent },
    PmenuKind = { fg = p.cyan, bg = menu },
    PmenuExtra = { fg = p.muted, bg = menu },

    -- Quickfix / location list ---------------------------------------------
    QuickFixLine = { bg = p.selection_bg, bold = true },
    qfFileName = { fg = accent },
    qfLineNr = { fg = p.muted },

    -- Diff mode -------------------------------------------------------------
    DiffAdd = { bg = ui.blend(p.green, p.bg, 0.18) },
    DiffChange = { bg = ui.blend(p.yellow, p.bg, 0.12) },
    DiffDelete = { fg = p.red, bg = ui.blend(p.red, p.bg, 0.18) },
    DiffText = { bg = ui.blend(p.yellow, p.bg, 0.3), bold = true },

    -- Messages --------------------------------------------------------------
    ErrorMsg = { fg = p.red, bold = true },
    WarningMsg = { fg = p.yellow },
    ModeMsg = { fg = p.muted },
    MoreMsg = { fg = p.green },
    Question = { fg = p.cyan },

    -- Window separators and folds ------------------------------------------
    WinSeparator = { fg = p.border },
    Folded = { fg = p.muted, bg = ui.blend(p.accent, p.bg, 0.06), italic = true },
    FoldColumn = { fg = p.muted },

    -- lazy.nvim -------------------------------------------------------------
    LazyNormal = { fg = p.fg, bg = "NONE" },
    LazyButton = { fg = p.fg, bg = p.panel },
    LazyButtonActive = { fg = ui.contrast(p.panel_soft), bg = p.panel_soft, bold = true },
    LazyH1 = { fg = ui.contrast(p.panel_soft), bg = p.panel_soft, bold = true },
    LazyH2 = { fg = accent, bold = true },
    LazySpecial = { fg = p.cyan },
    LazyProp = { fg = p.muted },
    LazyValue = { fg = p.green },
    LazyComment = { fg = p.muted, italic = true },
    LazyDir = { fg = p.blue },
    LazyUrl = { fg = p.blue, underline = true },
    LazyCommit = { fg = p.orange },
    LazyCommitType = { fg = p.purple, bold = true },
    LazyProgressDone = { fg = p.green, bold = true },
    LazyProgressTodo = { fg = p.muted },
    LazyReasonPlugin = { fg = p.purple },
    LazyReasonEvent = { fg = p.yellow },
    LazyReasonKeys = { fg = p.cyan },
    LazyReasonCmd = { fg = p.orange },
    LazyReasonFt = { fg = p.green },
    LazyReasonStart = { fg = p.red },
    LazyReasonSource = { fg = p.blue },
    LazyReasonRuntime = { fg = p.muted },
    LazyReasonRequire = { fg = p.pink },

    -- mason.nvim ------------------------------------------------------------
    MasonNormal = { fg = p.fg, bg = "NONE" },
    MasonHeader = { fg = ui.contrast(p.panel_soft), bg = p.panel_soft, bold = true },
    MasonHeaderSecondary = { fg = ui.contrast(p.panel_alt), bg = p.panel_alt, bold = true },
    MasonHighlight = { fg = accent },
    MasonHighlightBlock = { fg = ui.contrast(p.panel_alt), bg = p.panel_alt },
    MasonHighlightBlockBold = { fg = ui.contrast(p.panel_alt), bg = p.panel_alt, bold = true },
    MasonMuted = { fg = p.muted },
    MasonMutedBlock = { fg = on_panel, bg = p.panel },
    MasonError = { fg = p.red },
    MasonWarning = { fg = p.yellow },

    -- trouble.nvim ----------------------------------------------------------
    TroubleNormal = { fg = p.fg, bg = "NONE" },
    TroubleNormalNC = { fg = p.fg, bg = "NONE" },
    TroubleText = { fg = p.fg },
    TroubleCount = { fg = accent, bg = menu, bold = true },
    TroubleIndent = { fg = p.muted },
    TroubleSource = { fg = p.muted, italic = true },
    TroublePos = { fg = p.muted },
    TroubleFilename = { fg = accent, bold = true },

    -- Terminal windows ------------------------------------------------------
    StatusLineTerm = { fg = p.fg, bg = "NONE" },
    StatusLineTermNC = { fg = p.muted, bg = "NONE" },
  }
end

local function apply()
  local p = ui.palette()
  for name, spec in pairs(groups(p)) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

function M.setup()
  apply()
  ui.on_theme_change(ui.create_augroup("ChromeHighlights"), apply)
end

return M
