-- ui/neon_vomit.lua
-- Maximal neon highlight overrides layered on top of the base colorscheme.
-- Applied after ui/theme.lua for extra punch.

local ok, colors = pcall(require, 'ui.colors')
if not ok then return end

local function hl(g, o) vim.api.nvim_set_hl(0, g, o) end
local black = '#0b0f14'

-- Core groups
hl('Normal', { bg = 'NONE', fg = '#eaf6ff' })
hl('NormalFloat', { bg = 'NONE' })

-- Editor accents
hl('CursorLine', { bg = 'NONE' })
hl('ColorColumn', { bg = '#11151c' })

-- Syntax neon
hl('Comment', { fg = '#8a9099', italic = true })
hl('String', { fg = colors.neon.lime, bold = false })
hl('Character', { fg = colors.neon.lime })

hl('Keyword', { fg = colors.neon.hotpink })
hl('Conditional', { fg = colors.neon.hotpink })
hl('Repeat', { fg = colors.neon.hotpink })

hl('Function', { fg = '#ffd866', bold = false })
hl('Method', { fg = '#ffd866' })

hl('Identifier', { fg = '#cfe7ff' })
hl('Variable', { fg = '#cfe7ff' })
hl('Parameter', { fg = '#e8f2ff' })

-- Treesitter links to keep consistency
hl('@comment', { link = 'Comment' })
hl('@string', { link = 'String' })
hl('@keyword', { link = 'Keyword' })
hl('@conditional', { link = 'Conditional' })
hl('@repeat', { link = 'Repeat' })
hl('@function', { link = 'Function' })
hl('@method', { link = 'Method' })
hl('@variable', { link = 'Variable' })
hl('@parameter', { link = 'Parameter' })

-- Diagnostics pop
hl('DiagnosticError', { fg = colors.neon.hotpink, bold = true })
hl('DiagnosticWarn', { fg = '#ff9e64', bold = true })
hl('DiagnosticInfo', { fg = colors.neon.cyan })
hl('DiagnosticHint', { fg = colors.neon.lime })

-- Underlines for diagnostics
hl('DiagnosticUnderlineError', { sp = colors.neon.hotpink, undercurl = true })
hl('DiagnosticUnderlineWarn', { sp = '#ff9e64', undercurl = true })
hl('DiagnosticUnderlineInfo', { sp = colors.neon.cyan, undercurl = true })
hl('DiagnosticUnderlineHint', { sp = colors.neon.lime, undercurl = true })

-- Indent guides subtle + scope neon
hl('IblIndent', { fg = '#2b313a' })
hl('IblScope', { fg = colors.neon.purple })

-- Rainbow delimiters neon set
hl('RainbowDelimiterRed', { fg = colors.neon.hotpink })
hl('RainbowDelimiterYellow', { fg = '#ffd866' })
hl('RainbowDelimiterBlue', { fg = colors.neon.cyan })
hl('RainbowDelimiterOrange', { fg = '#ff9e64' })
hl('RainbowDelimiterGreen', { fg = colors.neon.lime })
hl('RainbowDelimiterViolet', { fg = colors.neon.purple })
hl('RainbowDelimiterCyan', { fg = '#7cecff' })

-- UI borders
hl('FloatBorder', { fg = colors.neon.purple, bg = 'NONE' })
hl('TelescopeBorder', { fg = colors.neon.purple, bg = 'NONE' })
hl('TelescopePromptBorder', { fg = colors.neon.purple, bg = 'NONE' })

-- Lualine theme is already tokyonight; keep contrast via NormalNC tweak
hl('NormalNC', { bg = 'NONE', fg = '#d8e9ff' })
