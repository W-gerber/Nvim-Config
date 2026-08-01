-- neon_vommit — a faithful base46 port of the "Neon Vommit" VS Code theme.
--
--   https://github.com/ghgofort/vscode-neon-vommit-theme
--
-- The palette below is transcribed from that theme's NeonVommitTheme.json, so
-- token colors match the original rather than approximating it. Its signature
-- is a near-neutral #222222 backdrop under very saturated accents: lime
-- functions, magenta keywords, cyan variables, lavender strings and pure-yellow
-- operators.
--
-- See lua/themes/README.md for how base_16 slots map onto highlight groups.

local palette = {
  -- Backdrop -----------------------------------------------------------------
  bg = "#222222", -- editor.background
  bg_dark = "#1a1a1a", -- sidebars, statusline
  bg_raised = "#2a2a2a",
  bg_raised2 = "#333333",
  bg_raised3 = "#3d3d3d",
  line = "#3a3a3a", -- editorRuler.foreground
  whitespace = "#4a4a4a", -- editorWhitespace.foreground
  selection = "#646464", -- editor.selectionBackground

  -- Text ---------------------------------------------------------------------
  fg = "#f0f0f0", -- editor.foreground
  fg_bright = "#ffffff",
  comment = "#bbaa99", -- warm grey, the theme's one desaturated token
  comment_dim = "#9a8d80",
  muted = "#8a8a8a",

  -- Accents ------------------------------------------------------------------
  magenta = "#ff00aa", -- keyword, storage, tag name
  lime = "#76ee00", -- function name, class name, attribute name
  cyan = "#66d9ef", -- variable, library constant, html string
  lavender = "#cbc3ff", -- string
  spring = "#33cc99", -- number
  blue = "#4499ff", -- constant (language + user defined)
  violet = "#bb77ff", -- object property
  purple = "#cc33ff", -- TypeScript types
  jade = "#00f9ac", -- jsdoc types
  plum = "#a467cc", -- jsdoc tags
  salmon = "#ff6f77", -- storage type
  orange = "#fd971f", -- function argument
  yellow = "#ffff00", -- operators
  sky = "#44b9ef", -- markdown emphasis
  term_green = "#33cc33", -- terminal.foreground
}

local M = {}

-- base_30 drives UI chrome (floats, menus, statusline, git signs, ...).
M.base_30 = {
  white = palette.fg,
  darker_black = palette.bg_dark,
  black = palette.bg,
  black2 = palette.bg_raised,
  one_bg = palette.bg_raised,
  one_bg2 = palette.bg_raised2,
  one_bg3 = palette.bg_raised3,
  grey = palette.whitespace,
  grey_fg = palette.comment, -- drives @comment
  grey_fg2 = palette.comment_dim,
  light_grey = palette.muted,
  red = palette.salmon,
  baby_pink = "#ff66c4",
  pink = palette.magenta,
  line = palette.line,
  green = palette.lime,
  vibrant_green = palette.spring,
  nord_blue = palette.blue,
  blue = palette.cyan,
  yellow = palette.yellow,
  sun = "#ffee44",
  purple = palette.purple,
  dark_purple = palette.violet,
  teal = palette.jade,
  orange = palette.orange,
  cyan = palette.cyan,
  statusline_bg = palette.bg_dark,
  lightbg = palette.bg_raised2,
  pmenu_bg = palette.lime,
  folder_bg = palette.cyan,
}

-- base_16 drives syntax. See the mapping table in lua/themes/README.md.
M.base_16 = {
  base00 = palette.bg,
  base01 = palette.bg_raised,
  base02 = palette.bg_raised2,
  base03 = palette.whitespace,
  base04 = palette.selection,
  base05 = palette.fg,
  base06 = "#f7f7f7",
  base07 = palette.fg_bright,
  base08 = palette.cyan, -- variables, parameters, members
  base09 = palette.spring, -- numbers, constants, booleans
  base0A = palette.purple, -- types
  base0B = palette.lavender, -- strings
  base0C = palette.jade, -- escapes, constructors, "special"
  base0D = palette.lime, -- functions
  base0E = palette.magenta, -- keywords
  base0F = palette.fg, -- punctuation stays neutral, as in VS Code
}

M.type = "dark"

-- ANSI palette for :terminal, taken from the theme's terminal.* keys where it
-- defines them and filled in from the syntax accents where it does not.
M.terminal = {
  [0] = "#102210", -- terminal.ansiBlack
  [1] = palette.magenta,
  [2] = palette.term_green,
  [3] = palette.yellow,
  [4] = palette.blue,
  [5] = palette.violet,
  [6] = palette.cyan,
  [7] = palette.fg,
  [8] = palette.whitespace,
  [9] = palette.salmon,
  [10] = palette.lime,
  [11] = "#ffee44",
  [12] = palette.cyan,
  [13] = palette.purple,
  [14] = palette.jade,
  [15] = palette.fg_bright,
}

-- Exact chrome colors, overriding lua/core/ui.lua's derivation. Without this
-- the derived "green" would come out lavender (this theme's strings are
-- lavender) and "purple" would come out magenta (its keywords are magenta).
M.ui_palette = {
  accent = palette.lime,
  blue = palette.blue,
  cyan = palette.cyan,
  green = palette.spring,
  yellow = palette.yellow,
  orange = palette.orange,
  red = palette.salmon,
  purple = palette.purple,
  pink = palette.magenta,
  muted = palette.muted,
  border = palette.line,
  panel = palette.bg_raised,
  panel_alt = palette.bg_raised2,
  panel_soft = palette.bg_raised3,
  selection_bg = palette.selection,
  selection_fg = palette.fg_bright,
  modes = {
    n = palette.lime,
    i = palette.spring,
    v = palette.magenta,
    V = palette.magenta,
    ["\22"] = palette.magenta,
    s = palette.magenta,
    S = palette.magenta,
    R = palette.salmon,
    c = palette.yellow,
    t = palette.cyan,
  },
}

M.neon_glow = {
  enabled = true,
  accent = palette.lime,
  secondary = palette.magenta,
}

-- polish_hl carries everything the base_16 slots cannot express on their own:
-- tokens whose color differs from the slot base46 would assign them, and
-- per-language overrides. Keys are base46 integration names.
M.polish_hl = {
  syntax = {
    Comment = { fg = palette.comment, italic = true },
    Operator = { fg = palette.yellow },
    Delimiter = { fg = palette.fg },
    Tag = { fg = palette.magenta },
    StorageClass = { fg = palette.salmon },
    Structure = { fg = palette.purple },
    Typedef = { fg = palette.purple },
    Special = { fg = palette.jade },
    SpecialChar = { fg = palette.jade },
    Todo = { fg = palette.bg, bg = palette.yellow, bold = true },
  },

  treesitter = {
    -- Comments ---------------------------------------------------------------
    ["@comment"] = { fg = palette.comment, italic = true },
    ["@comment.documentation"] = { fg = palette.comment_dim, italic = true },

    -- Variables and members --------------------------------------------------
    ["@variable"] = { fg = palette.fg },
    ["@variable.builtin"] = { fg = palette.blue },
    ["@variable.parameter"] = { fg = palette.orange },
    ["@variable.member"] = { fg = palette.violet },
    ["@property"] = { fg = palette.violet },
    ["@field"] = { fg = palette.violet },

    -- Constants and literals -------------------------------------------------
    ["@constant"] = { fg = palette.blue },
    ["@constant.builtin"] = { fg = palette.blue },
    ["@constant.macro"] = { fg = palette.blue },
    ["@number"] = { fg = palette.spring },
    ["@number.float"] = { fg = palette.spring },
    ["@boolean"] = { fg = palette.blue },
    ["@string"] = { fg = palette.lavender },
    ["@string.regexp"] = { fg = palette.fg },
    ["@string.escape"] = { fg = palette.jade },
    ["@string.special"] = { fg = palette.jade },
    ["@character"] = { fg = palette.lavender },

    -- Keywords and operators -------------------------------------------------
    ["@keyword"] = { fg = palette.magenta },
    ["@keyword.function"] = { fg = palette.magenta },
    ["@keyword.return"] = { fg = palette.magenta },
    ["@keyword.conditional"] = { fg = palette.magenta },
    ["@keyword.repeat"] = { fg = palette.magenta },
    ["@keyword.exception"] = { fg = palette.magenta },
    ["@keyword.import"] = { fg = palette.magenta },
    ["@keyword.operator"] = { fg = palette.yellow },
    ["@keyword.modifier"] = { fg = palette.salmon },
    ["@keyword.type"] = { fg = palette.salmon },
    ["@keyword.coroutine"] = { fg = palette.magenta },
    ["@operator"] = { fg = palette.yellow },

    -- Callables --------------------------------------------------------------
    ["@function"] = { fg = palette.lime },
    ["@function.call"] = { fg = palette.lime },
    ["@function.builtin"] = { fg = palette.lime },
    ["@function.method"] = { fg = palette.lime },
    ["@function.method.call"] = { fg = palette.lime },
    ["@function.macro"] = { fg = palette.lime },
    ["@constructor"] = { fg = palette.lime },

    -- Types ------------------------------------------------------------------
    ["@type"] = { fg = palette.purple },
    ["@type.builtin"] = { fg = palette.salmon },
    ["@type.definition"] = { fg = palette.purple },
    ["@module"] = { fg = palette.cyan },
    ["@attribute"] = { fg = palette.lime },
    ["@label"] = { fg = palette.magenta },

    -- Punctuation stays neutral so the neon accents carry the eye -------------
    ["@punctuation.bracket"] = { fg = palette.fg },
    ["@punctuation.delimiter"] = { fg = palette.fg },
    ["@punctuation.special"] = { fg = palette.yellow },

    -- Markup / Markdown ------------------------------------------------------
    ["@markup.heading"] = { fg = palette.lime, bold = true },
    ["@markup.heading.1"] = { fg = palette.magenta, bold = true },
    ["@markup.heading.2"] = { fg = palette.lime, bold = true },
    ["@markup.heading.3"] = { fg = palette.cyan, bold = true },
    ["@markup.strong"] = { fg = palette.sky, bold = true },
    ["@markup.italic"] = { fg = palette.sky, italic = true },
    ["@markup.strikethrough"] = { fg = palette.muted, strikethrough = true },
    ["@markup.raw"] = { fg = palette.lavender },
    ["@markup.raw.block"] = { fg = palette.lavender },
    ["@markup.link"] = { fg = palette.lime, underline = true },
    ["@markup.link.url"] = { fg = palette.cyan, underline = true },
    ["@markup.link.label"] = { fg = palette.lime },
    ["@markup.list"] = { fg = palette.magenta },
    ["@markup.quote"] = { fg = palette.comment, italic = true },

    -- Diff -------------------------------------------------------------------
    ["@diff.plus"] = { fg = palette.lime },
    ["@diff.minus"] = { fg = palette.salmon },
    ["@diff.delta"] = { fg = palette.orange },

    -- HTML / JSX / TSX -------------------------------------------------------
    ["@tag"] = { fg = palette.magenta },
    ["@tag.builtin"] = { fg = palette.magenta },
    ["@tag.attribute"] = { fg = palette.lime },
    ["@tag.delimiter"] = { fg = palette.cyan },

    -- CSS / Tailwind ---------------------------------------------------------
    ["@property.css"] = { fg = palette.cyan },
    ["@type.css"] = { fg = palette.lime },
    ["@string.css"] = { fg = palette.lavender },
    ["@number.css"] = { fg = palette.spring },
    ["@function.call.css"] = { fg = palette.salmon },
    ["@attribute.css"] = { fg = palette.lime },
    ["@property.scss"] = { fg = palette.cyan },

    -- JSON / JSONC -----------------------------------------------------------
    ["@property.json"] = { fg = palette.cyan },
    ["@string.json"] = { fg = palette.lavender },
    ["@number.json"] = { fg = palette.spring },
    ["@boolean.json"] = { fg = palette.blue },
    ["@property.jsonc"] = { fg = palette.cyan },

    -- JavaScript / TypeScript ------------------------------------------------
    ["@type.typescript"] = { fg = palette.purple },
    ["@type.tsx"] = { fg = palette.purple },
    ["@variable.member.typescript"] = { fg = palette.violet },
    ["@keyword.import.javascript"] = { fg = palette.magenta },
    ["@keyword.import.typescript"] = { fg = palette.magenta },

    -- Lua --------------------------------------------------------------------
    ["@constructor.lua"] = { fg = palette.fg },
    ["@variable.member.lua"] = { fg = palette.violet },

    -- Python -----------------------------------------------------------------
    ["@type.python"] = { fg = palette.purple },
    ["@variable.builtin.python"] = { fg = palette.blue },
    ["@function.builtin.python"] = { fg = palette.lime },
    ["@attribute.python"] = { fg = palette.plum },

    -- Rust -------------------------------------------------------------------
    ["@type.rust"] = { fg = palette.purple },
    ["@attribute.rust"] = { fg = palette.plum },
    ["@keyword.modifier.rust"] = { fg = palette.salmon },
    ["@function.macro.rust"] = { fg = palette.lime },
    ["@variable.builtin.rust"] = { fg = palette.blue },

    -- Go ---------------------------------------------------------------------
    ["@type.go"] = { fg = palette.purple },
    ["@keyword.import.go"] = { fg = palette.magenta },
    ["@variable.member.go"] = { fg = palette.violet },
    ["@constant.builtin.go"] = { fg = palette.blue },

    -- Java / C# --------------------------------------------------------------
    ["@type.java"] = { fg = palette.purple },
    ["@keyword.modifier.java"] = { fg = palette.salmon },
    ["@attribute.java"] = { fg = palette.plum },
    ["@type.c_sharp"] = { fg = palette.purple },
    ["@keyword.modifier.c_sharp"] = { fg = palette.salmon },
    ["@attribute.c_sharp"] = { fg = palette.plum },

    -- SQL --------------------------------------------------------------------
    ["@keyword.sql"] = { fg = palette.magenta },
    ["@type.sql"] = { fg = palette.purple },
    ["@function.call.sql"] = { fg = palette.lime },
    ["@string.sql"] = { fg = palette.lavender },
  },

  defaults = {
    Visual = { bg = palette.selection },
    CursorLine = { bg = palette.bg_raised },
    Search = { fg = palette.bg, bg = palette.yellow, bold = true },
    IncSearch = { fg = palette.bg, bg = palette.lime, bold = true },
    CurSearch = { fg = palette.bg, bg = palette.lime, bold = true },
    MatchParen = { fg = palette.yellow, bg = palette.bg_raised3, bold = true },
    NonText = { fg = palette.whitespace },
    Whitespace = { fg = palette.whitespace },
    WinSeparator = { fg = palette.line },
  },
}

local ok_base46, base46 = pcall(require, "base46")
if ok_base46 then
  M = base46.override_theme(M, "neon_vommit")
end

return M
