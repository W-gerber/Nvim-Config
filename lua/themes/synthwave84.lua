-- synthwave84 — a faithful base46 port of the "SynthWave '84" VS Code theme.
--
--   https://github.com/robb0wen/synthwave-vscode
--
-- Transcribed from that theme's synthwave-color-theme.json. The identity is a
-- deep violet backdrop (#262335) under a retro-futurist palette: yellow
-- keywords, cyan functions, pink variables, orange strings, salmon constants
-- and mint tags.
--
-- The original's glow is a VS Code shader hack and has no terminal equivalent.
-- What carries over is its contrast: saturated foregrounds on very dark violet
-- surfaces, plus bold accents on the chrome (see `neon_glow` below, which the
-- theme layer uses to add the emphasis a real glow would have provided).
--
-- See lua/themes/README.md for how base_16 slots map onto highlight groups.

local palette = {
  -- Backdrop -----------------------------------------------------------------
  bg = "#262335", -- editor.background
  bg_dark = "#1f1a2e",
  bg_darkest = "#171520", -- activityBar.background
  sidebar = "#241b2f", -- sideBar / statusBar background
  panel = "#2a2139", -- input / widget background
  raised = "#34294f", -- word highlight, hover
  raised2 = "#463465", -- menu background
  border = "#495495", -- editorGroup.border, peekView.border
  indent = "#444251", -- editorIndentGuide.background
  indent_active = "#a148ab", -- editorIndentGuide.activeBackground

  -- Text ---------------------------------------------------------------------
  fg = "#ffffff",
  fg_dim = "#b6b1b1", -- punctuation, separators
  comment = "#848bbd", -- comment (italic in the original)
  comment_dim = "#6d74a4",
  muted = "#9d8bca", -- scrollbar slider

  -- Accents ------------------------------------------------------------------
  yellow = "#fede5d", -- keyword, storage, operator, attribute
  yellow_hot = "#f3e70f", -- terminal.ansiYellow
  cyan = "#36f9f6", -- function, escape, id selector
  cyan_bright = "#03edf9", -- terminal.ansiCyan
  cyan_soft = "#2ee2fa", -- numerics, markdown emphasis
  pink = "#ff7edb", -- variable, property, heading
  red = "#fe4450", -- class, type, entity, support
  salmon = "#f97e72", -- constant, number, regex, cursor
  orange = "#ff8b39", -- string
  amber = "#d50000", -- inherited class, pseudo selectors, links
  mint = "#72f1b8", -- tag, css property, export
  mint_bright = "#09f7a0", -- added / diff
  lilac = "#b893ce", -- modified / git
}

local M = {}

-- base_30 drives UI chrome (floats, menus, statusline, git signs, ...).
M.base_30 = {
  white = palette.fg,
  darker_black = palette.bg_darkest,
  black = palette.bg,
  black2 = palette.panel,
  one_bg = palette.sidebar,
  one_bg2 = palette.raised,
  one_bg3 = palette.raised2,
  grey = palette.border,
  grey_fg = palette.comment, -- drives @comment
  grey_fg2 = palette.comment_dim,
  light_grey = palette.fg_dim,
  red = palette.red,
  baby_pink = palette.pink,
  pink = palette.pink,
  line = palette.raised,
  green = palette.mint,
  vibrant_green = palette.mint_bright,
  nord_blue = palette.cyan_bright,
  blue = palette.cyan,
  yellow = palette.yellow,
  sun = palette.yellow_hot,
  purple = palette.lilac,
  dark_purple = palette.indent_active,
  teal = palette.cyan_soft,
  orange = palette.orange,
  cyan = palette.cyan_bright,
  statusline_bg = palette.sidebar,
  lightbg = palette.panel,
  pmenu_bg = palette.pink,
  folder_bg = palette.cyan,
}

-- base_16 drives syntax. See the mapping table in lua/themes/README.md.
M.base_16 = {
  base00 = palette.bg,
  base01 = palette.panel,
  base02 = palette.raised,
  base03 = palette.border,
  base04 = palette.comment,
  base05 = palette.fg,
  base06 = "#f0eff1",
  base07 = palette.fg,
  base08 = palette.pink, -- variables, parameters, members
  base09 = palette.salmon, -- numbers, constants, booleans
  base0A = palette.red, -- types
  base0B = palette.orange, -- strings
  base0C = palette.cyan, -- escapes, constructors, "special"
  base0D = palette.cyan, -- functions
  base0E = palette.yellow, -- keywords
  base0F = palette.fg_dim, -- punctuation
}

M.type = "dark"

-- ANSI palette straight from the theme's terminal.* keys.
M.terminal = {
  [0] = palette.panel,
  [1] = palette.red,
  [2] = palette.mint,
  [3] = palette.yellow_hot,
  [4] = palette.cyan_bright,
  [5] = palette.pink,
  [6] = palette.cyan,
  [7] = palette.fg,
  [8] = palette.border,
  [9] = palette.red,
  [10] = palette.mint,
  [11] = palette.yellow,
  [12] = palette.cyan_bright,
  [13] = palette.pink,
  [14] = palette.cyan_bright,
  [15] = palette.fg,
}

-- Consumed by lua/core/ui.lua: themes that want extra emphasis on chrome (the
-- closest a terminal gets to the original's bloom shader) opt in here.
M.neon_glow = {
  enabled = true,
  accent = palette.pink,
  secondary = palette.cyan,
}

-- Exact chrome colors, overriding lua/core/ui.lua's derivation. Without this
-- the derived "green" would come out orange (this theme's strings are orange)
-- and "purple" would come out yellow (its keywords are yellow).
M.ui_palette = {
  accent = palette.pink,
  blue = palette.cyan_bright,
  cyan = palette.cyan,
  green = palette.mint,
  yellow = palette.yellow,
  orange = palette.orange,
  red = palette.red,
  purple = palette.lilac,
  pink = palette.pink,
  muted = palette.comment,
  border = palette.border,
  panel = palette.panel,
  panel_alt = palette.raised,
  panel_soft = palette.raised2,
  selection_bg = palette.raised,
  selection_fg = palette.fg,
  modes = {
    n = palette.pink,
    i = palette.mint,
    v = palette.yellow,
    V = palette.yellow,
    ["\22"] = palette.yellow,
    s = palette.yellow,
    S = palette.yellow,
    R = palette.red,
    c = palette.salmon,
    t = palette.cyan,
  },
}

-- polish_hl carries everything the base_16 slots cannot express on their own:
-- tokens whose color differs from the slot base46 would assign them, and
-- per-language overrides. Keys are base46 integration names.
M.polish_hl = {
  syntax = {
    Comment = { fg = palette.comment, italic = true },
    Operator = { fg = palette.yellow },
    Delimiter = { fg = palette.fg_dim },
    Tag = { fg = palette.mint },
    StorageClass = { fg = palette.yellow },
    Structure = { fg = palette.red },
    Typedef = { fg = palette.red },
    Repeat = { fg = palette.yellow },
    Label = { fg = palette.yellow },
    PreProc = { fg = palette.mint },
    Special = { fg = palette.cyan },
    SpecialChar = { fg = palette.cyan },
    Todo = { fg = palette.bg, bg = palette.yellow, bold = true },
  },

  treesitter = {
    -- Comments ---------------------------------------------------------------
    ["@comment"] = { fg = palette.comment, italic = true },
    ["@comment.documentation"] = { fg = palette.comment_dim, italic = true },

    -- Variables and members --------------------------------------------------
    ["@variable"] = { fg = palette.pink },
    ["@variable.builtin"] = { fg = palette.red, bold = true },
    ["@variable.parameter"] = { fg = palette.pink, italic = true },
    ["@variable.member"] = { fg = palette.pink },
    ["@property"] = { fg = palette.pink },
    ["@field"] = { fg = palette.pink },

    -- Constants and literals -------------------------------------------------
    ["@constant"] = { fg = palette.salmon },
    ["@constant.builtin"] = { fg = palette.salmon },
    ["@constant.macro"] = { fg = palette.salmon },
    ["@number"] = { fg = palette.salmon },
    ["@number.float"] = { fg = palette.salmon },
    ["@boolean"] = { fg = palette.salmon },
    ["@string"] = { fg = palette.orange },
    ["@string.regexp"] = { fg = palette.salmon },
    ["@string.escape"] = { fg = palette.cyan },
    ["@string.special"] = { fg = palette.cyan },
    ["@string.special.url"] = { fg = palette.amber, underline = true },
    ["@character"] = { fg = palette.orange },

    -- Keywords and operators -------------------------------------------------
    ["@keyword"] = { fg = palette.yellow },
    ["@keyword.function"] = { fg = palette.yellow },
    ["@keyword.return"] = { fg = palette.yellow },
    ["@keyword.conditional"] = { fg = palette.yellow },
    ["@keyword.repeat"] = { fg = palette.yellow },
    ["@keyword.exception"] = { fg = palette.yellow },
    ["@keyword.import"] = { fg = palette.mint },
    ["@keyword.modifier"] = { fg = palette.yellow },
    ["@keyword.type"] = { fg = palette.yellow },
    ["@keyword.coroutine"] = { fg = palette.yellow },
    ["@keyword.directive"] = { fg = palette.mint },
    ["@operator"] = { fg = palette.yellow },

    -- Callables --------------------------------------------------------------
    ["@function"] = { fg = palette.cyan },
    ["@function.call"] = { fg = palette.cyan },
    ["@function.builtin"] = { fg = palette.cyan },
    ["@function.method"] = { fg = palette.cyan },
    ["@function.method.call"] = { fg = palette.cyan },
    ["@function.macro"] = { fg = palette.cyan },
    ["@constructor"] = { fg = palette.red },

    -- Types ------------------------------------------------------------------
    ["@type"] = { fg = palette.red },
    ["@type.builtin"] = { fg = palette.red },
    ["@type.definition"] = { fg = palette.red },
    ["@module"] = { fg = palette.pink },
    ["@attribute"] = { fg = palette.yellow },
    ["@label"] = { fg = palette.mint },

    -- Punctuation --------------------------------------------------------------
    ["@punctuation.bracket"] = { fg = palette.fg_dim },
    ["@punctuation.delimiter"] = { fg = palette.fg_dim },
    ["@punctuation.special"] = { fg = palette.mint },

    -- Markup / Markdown ------------------------------------------------------
    ["@markup.heading"] = { fg = palette.pink, bold = true },
    ["@markup.heading.1"] = { fg = palette.pink, bold = true },
    ["@markup.heading.2"] = { fg = palette.cyan, bold = true },
    ["@markup.heading.3"] = { fg = palette.mint, bold = true },
    ["@markup.strong"] = { fg = palette.cyan_soft, bold = true },
    ["@markup.italic"] = { fg = palette.cyan_soft, italic = true },
    ["@markup.strikethrough"] = { fg = palette.fg_dim, strikethrough = true },
    ["@markup.raw"] = { fg = palette.mint, italic = true },
    ["@markup.raw.block"] = { fg = palette.mint },
    ["@markup.link"] = { fg = palette.amber, underline = true },
    ["@markup.link.url"] = { fg = palette.mint, italic = true, underline = true },
    ["@markup.link.label"] = { fg = palette.yellow },
    ["@markup.list"] = { fg = palette.pink },
    ["@markup.quote"] = { fg = palette.mint, italic = true },

    -- Diff -------------------------------------------------------------------
    ["@diff.plus"] = { fg = palette.mint_bright },
    ["@diff.minus"] = { fg = palette.red },
    ["@diff.delta"] = { fg = palette.lilac },

    -- HTML / JSX / TSX -------------------------------------------------------
    ["@tag"] = { fg = palette.mint },
    ["@tag.builtin"] = { fg = palette.mint },
    ["@tag.attribute"] = { fg = palette.yellow, italic = true },
    ["@tag.delimiter"] = { fg = palette.cyan },

    -- CSS / Tailwind ---------------------------------------------------------
    ["@property.css"] = { fg = palette.mint },
    ["@type.css"] = { fg = palette.red },
    ["@string.css"] = { fg = palette.orange },
    ["@number.css"] = { fg = palette.salmon },
    ["@constant.css"] = { fg = palette.salmon },
    ["@function.call.css"] = { fg = palette.red },
    ["@attribute.css"] = { fg = palette.cyan },
    ["@property.scss"] = { fg = palette.mint },

    -- JSON / JSONC -----------------------------------------------------------
    ["@property.json"] = { fg = palette.mint },
    ["@string.json"] = { fg = palette.orange },
    ["@number.json"] = { fg = palette.salmon },
    ["@boolean.json"] = { fg = palette.salmon },
    ["@property.jsonc"] = { fg = palette.mint },

    -- JavaScript / TypeScript ------------------------------------------------
    ["@keyword.import.javascript"] = { fg = palette.mint },
    ["@keyword.import.typescript"] = { fg = palette.mint },
    ["@keyword.export.javascript"] = { fg = palette.mint },
    ["@number.javascript"] = { fg = palette.cyan_soft },
    ["@number.typescript"] = { fg = palette.cyan_soft },
    ["@variable.member.javascript"] = { fg = palette.cyan_soft },
    ["@type.typescript"] = { fg = palette.red },
    ["@type.tsx"] = { fg = palette.red },

    -- Lua --------------------------------------------------------------------
    ["@constructor.lua"] = { fg = palette.fg_dim },
    ["@variable.member.lua"] = { fg = palette.pink },

    -- Python -----------------------------------------------------------------
    ["@variable.python"] = { fg = palette.pink },
    ["@function.call.python"] = { fg = palette.cyan },
    ["@variable.parameter.python"] = { fg = palette.mint },
    ["@type.python"] = { fg = palette.red },

    -- Rust -------------------------------------------------------------------
    ["@type.rust"] = { fg = palette.red },
    ["@attribute.rust"] = { fg = palette.mint },
    ["@keyword.modifier.rust"] = { fg = palette.yellow },
    ["@function.macro.rust"] = { fg = palette.cyan },
    ["@variable.builtin.rust"] = { fg = palette.red, bold = true },

    -- Go ---------------------------------------------------------------------
    ["@variable.go"] = { fg = palette.pink },
    ["@function.call.go"] = { fg = palette.cyan },
    ["@keyword.import.go"] = { fg = palette.yellow },
    ["@type.go"] = { fg = palette.mint },
    ["@constant.builtin.go"] = { fg = palette.cyan_soft },

    -- Java / C# --------------------------------------------------------------
    ["@type.java"] = { fg = palette.red },
    ["@keyword.modifier.java"] = { fg = palette.yellow },
    ["@variable.member.java"] = { fg = palette.pink },
    ["@type.c_sharp"] = { fg = palette.red },
    ["@keyword.modifier.c_sharp"] = { fg = palette.red },
    ["@variable.member.c_sharp"] = { fg = palette.pink },
    ["@variable.c_sharp"] = { fg = palette.pink },

    -- SQL --------------------------------------------------------------------
    ["@keyword.sql"] = { fg = palette.yellow },
    ["@type.sql"] = { fg = palette.red },
    ["@function.call.sql"] = { fg = palette.cyan },
    ["@string.sql"] = { fg = palette.orange },
  },

  defaults = {
    Visual = { bg = palette.raised },
    CursorLine = { bg = palette.panel },
    Search = { fg = palette.fg, bg = "#d18616", bold = true },
    IncSearch = { fg = palette.bg, bg = palette.pink, bold = true },
    CurSearch = { fg = palette.bg, bg = palette.pink, bold = true },
    MatchParen = { fg = palette.cyan, bg = palette.raised, bold = true },
    NonText = { fg = palette.indent },
    Whitespace = { fg = palette.indent },
    WinSeparator = { fg = palette.border },
  },
}

local ok_base46, base46 = pcall(require, "base46")
if ok_base46 then
  M = base46.override_theme(M, "synthwave84")
end

return M
