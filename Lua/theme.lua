local M = {}

M.neon = {
    cyan      = "#00d7ff",
    hotpink   = "#ff2d95",
    lime      = "#b7ff3a",
    purple    = "#9d7cff",
    orange    = "#ff9e1b",
    white     = "#ffffff",
    gray      = "#808080",
    neon_Yellow = "#CFFF04",
    light_purple = "#d6afff",
    blue      = "#1e90ff",


}

local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

local function link(from, to)
    vim.api.nvim_set_hl(0, from, { link = to })
end

function M.setup()
    local c = M.neon

    -- Base UI (keep background transparent for maximum compatibility)
    hl("Normal", { fg = c.white, bg = "NONE" })
    hl("NormalNC", { fg = c.white, bg = "NONE" })
    hl("NormalFloat", { fg = c.white, bg = "NONE" })
    hl("FloatBorder", { fg = c.purple, bg = "NONE" })

    hl("LineNr", { fg = c.gray, bg = "NONE" })
    hl("CursorLineNr", { fg = c.hotpink, bg = "NONE" })
    hl("CursorLine", { bg = "NONE" })

    hl("Visual", { fg = c.white, bg = c.purple })
    hl("Search", { fg = c.white, bg = c.orange })
    hl("IncSearch", { fg = c.white, bg = c.orange })

    hl("StatusLine", { fg = c.white, bg = "NONE" })
    hl("StatusLineNC", { fg = c.purple, bg = "NONE" })

    -- Core syntax groups (match requested palette mappings)
    hl("Comment", { fg = c.gray, italic = true })

    hl("Keyword", { fg = c.neon_Yellow })
    hl("Conditional", { fg = c.hotpink })
    hl("Repeat", { fg = c.hotpink })
    hl("Label", { fg = c.hotpink })
    hl("Exception", { fg = c.hotpink })
    hl("Statement", { fg = c.hotpink })
    hl("PreProc", { fg = c.hotpink })
    hl("Include", { fg = c.hotpink })
    hl("Define", { fg = c.hotpink })
    hl("Macro", { fg = c.hotpink })
    hl("PreCondit", { fg = c.hotpink })

    hl("Function", { fg = c.hotpink })
  

    hl("String", { fg = c.light_purple})    -- make violet 
    hl("Character", { fg = c.light_purple }) 

    -- Variables / parameters
    hl("Identifier", { fg = c.orange }) -- dont know about this change 2

    -- Operators / punctuation
    hl("Operator", { fg = c.hotpink })
    hl("Delimiter", { fg = c.white })   -- dont know what changed
    hl("SpecialChar", { fg = c.blue })

    -- A few common extras for completeness (still constrained to palette)
    hl("Constant", { fg = c.blue })
    hl("Number", { fg = c.orange })
    hl("Boolean", { fg = c.orange })
    hl("Float", { fg = c.orange })
    hl("Type", { fg = c.cyan })

    -- Treesitter groups (Neovim 0.8+). Link to the canonical groups above.
    link("@comment", "Comment")

    link("@keyword", "Keyword")
    link("@keyword.conditional", "Keyword")
    link("@keyword.repeat", "Keyword")
    link("@keyword.return", "Keyword")
    link("@keyword.import", "Keyword")
    link("@keyword.operator", "Keyword")
    link("@conditional", "Keyword")

    link("@function", "Function")
    link("@function.call", "Function")
    link("@method", "Function")
    link("@method.call", "Function")
    link("@constructor", "Function")

    link("@string", "String")
    link("@string.escape", "String")
    link("@string.regex", "String")
    link("@character", "String")

    link("@variable", "Identifier")
    link("@variable.builtin", "Identifier")
    link("@parameter", "Identifier")
    link("@field", "Identifier")
    link("@property", "Identifier")

    link("@operator", "Operator")
    link("@punctuation", "Delimiter")
    link("@punctuation.delimiter", "Delimiter")
    link("@punctuation.bracket", "Delimiter")
    link("@punctuation.special", "Delimiter")

    link("@constant", "Constant")
    link("@constant.builtin", "Constant")
    link("@number", "Number")
    link("@boolean", "Boolean")

    link("@type", "Type")
    link("@type.builtin", "Type")
end

return M
