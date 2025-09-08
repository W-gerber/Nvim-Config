-- ui/theme.lua
local ok, colors = pcall(require, "ui.colors")
if not ok then
	colors = { neon = { cyan = "#00d7ff", hotpink = "#ff2d95", lime = "#b7ff3a", purple = "#9d7cff" } }
end

-- Helper
local function hl(group, opts) vim.api.nvim_set_hl(0, group, opts) end

-- Global transparency / glassy look
hl('Normal', { bg = 'NONE' })
hl('NormalFloat', { bg = 'NONE' })
hl('FloatBorder', { bg = 'NONE', fg = colors.neon.purple })

-- Cursorline and selection
hl('CursorLine', { bg = 'NONE', underline = false })
hl('Visual', { bg = colors.neon.cyan, fg = '#000000' })

-- Search and IncSearch
hl('Search', { fg = '#000000', bg = colors.neon.hotpink, bold = true })
hl('IncSearch', { fg = '#000000', bg = colors.neon.lime, bold = true })

-- Bufferline / active buffer
hl('BufferLineBufferSelected', { bg = colors.neon.cyan, fg = '#000000', bold = true })
hl('BufferLineFill', { bg = 'NONE' })

-- Telescope
hl('TelescopeBorder', { fg = colors.neon.purple, bg = 'NONE' })
hl('TelescopePromptBorder', { fg = colors.neon.purple, bg = 'NONE' })
hl('TelescopePromptNormal', { bg = 'NONE' })
hl('TelescopePreviewBorder', { fg = colors.neon.purple, bg = 'NONE' })
hl('TelescopeResultsBorder', { fg = colors.neon.purple, bg = 'NONE' })

-- Floating windows and completion
hl('Pmenu', { bg = 'NONE' })
hl('PmenuSel', { bg = colors.neon.hotpink, fg = '#000000' })
hl('PmenuSbar', { bg = 'NONE' })
hl('PmenuThumb', { bg = colors.neon.purple })

-- Neo-tree
hl('NeoTreeNormal', { bg = 'NONE' })
hl('NeoTreeNormalNC', { bg = 'NONE' })

-- Git signs
hl('GitSignsAdd', { fg = colors.neon.lime })
hl('GitSignsChange', { fg = colors.neon.cyan })
hl('GitSignsDelete', { fg = colors.neon.hotpink })

-- Diagnostics
hl('DiagnosticError', { fg = colors.neon.hotpink })
hl('DiagnosticWarn', { fg = '#ff9e64' })
hl('DiagnosticInfo', { fg = colors.neon.cyan })
hl('DiagnosticHint', { fg = colors.neon.lime })

-- LSP highlights
hl('LspReferenceText', { bg = colors.neon.purple, fg = '#000000' })
hl('LspReferenceRead', { bg = colors.neon.purple, fg = '#000000' })
hl('LspReferenceWrite', { bg = colors.neon.purple, fg = '#000000' })

-- Quickfix and others
hl('TroubleText', { fg = colors.neon.hotpink })

-- Indent blankline
hl('IblIndent', { fg = '#2a2e36' })
hl('IblScope', { fg = colors.neon.purple })

-- Alpha dashboard specific highlights
hl('AlphaHeader', { fg = colors.neon.cyan, bold = true })
hl('AlphaButtons', { fg = colors.neon.hotpink })
hl('AlphaShortcut', { fg = colors.neon.lime, bold = true })
hl('AlphaFooter', { fg = colors.neon.purple, italic = true })

-- Neovide hint (if running)
if vim.g.neovide then
	vim.g.neovide_transparency = 0.85
	vim.g.neovide_background_color = '#000000' .. '00'
end
