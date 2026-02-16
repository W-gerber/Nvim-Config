return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lsp",
    "onsails/lspkind.nvim",  -- Icons for completion items
    "L3MON4D3/LuaSnip",  -- Snippet engine
    "saadparwaiz1/cmp_luasnip",  -- Snippet completion source
    "zbirenbaum/copilot-cmp",
  },
  config = function()
    local ok_cmp, cmp = pcall(require, "cmp")
    if not ok_cmp then
      return
    end

    -- VS Code–style inline documentation:
    -- nvim-cmp can show a bordered documentation window for the *currently selected*
    -- completion item. For LSP items, docs come from the LSP. For Neovim `:set` options,
    -- we register a small custom source that attaches type/default/description.
    pcall(function()
      local src = require("cmp_sources.nvim_options").new()
      cmp.register_source("nvim_options", src)
    end)

    pcall(function()
      require("copilot_cmp").setup()
    end)

    local ok_lspkind, lspkind = pcall(require, "lspkind")
    local ok_luasnip, luasnip = pcall(require, "luasnip")

    -- Setup LuaSnip if available
    if ok_luasnip then
      pcall(function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end)
    end

    local function has_words_before()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      if col == 0 then
        return false
      end
      local text = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1] or ""
      local prev = text:sub(col, col)
      return prev:match("%s") == nil
    end

    cmp.setup({
      preselect = cmp.PreselectMode.Item,

      view = {
        docs = {
          auto_open = true,
        },
      },

      snippet = {
        expand = function(args)
          if ok_luasnip then
            luasnip.lsp_expand(args.body)
          end
        end,
      },

      window = {
        completion = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "Normal:CmpNormal,FloatBorder:CmpBorder,CursorLine:CmpSelection,Search:None",
          scrollbar = true,
          col_offset = -1,
          side_padding = 1,
        }),
        documentation = cmp.config.window.bordered({
          border = "rounded",
          winhighlight = "Normal:CmpDocNormal,FloatBorder:CmpDocBorder",
          max_height = 15,
          max_width = 80,
          col_offset = 1,
          side_padding = 1,
        }),
      },

      formatting = {
        -- Layout: [icon]  word                      Kind
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          local kind_label = vim_item.kind or ""

          -- Icon on the far left
          if ok_lspkind then
            local icon = lspkind.symbol_map[kind_label] or ""
            vim_item.kind = icon ~= "" and (icon .. " ") or ""
          else
            vim_item.kind = ""
          end

          -- Kind label on the right (muted)
          vim_item.menu = kind_label

          -- Truncate long abbr
          local max_abbr = 36
          if vim_item.abbr and #vim_item.abbr > max_abbr then
            vim_item.abbr = vim_item.abbr:sub(1, max_abbr - 1) .. "…"
          end

          return vim_item
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
            return
          end

          if ok_luasnip and luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
            return
          end

          if has_words_before() then
            cmp.complete()
            return
          end

          fallback()
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
            return
          end

          if ok_luasnip and luasnip.jumpable(-1) then
            luasnip.jump(-1)
            return
          end

          fallback()
        end, { "i", "s" }),
      }),

      sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 1000 },
        { name = "copilot", priority = 900 },
        { name = "luasnip", priority = 750 },
        { name = "path", priority = 500 },
      }, {
        { name = "buffer", priority = 250, keyword_length = 3 },
      }),

      experimental = {
        ghost_text = false,  -- disabled; copilot.lua renders inline suggestions
      },
    })

    -- Shared bordered window configs (avoids repeating in cmdline setups)
    local bordered_completion = cmp.config.window.bordered({
      border = "rounded",
      winhighlight = "Normal:CmpNormal,FloatBorder:CmpBorder,CursorLine:CmpSelection,Search:None",
      scrollbar = true,
      col_offset = -1,
      side_padding = 1,
    })
    local bordered_documentation = cmp.config.window.bordered({
      border = "rounded",
      winhighlight = "Normal:CmpDocNormal,FloatBorder:CmpDocBorder",
      max_height = 15,
      max_width = 80,
      col_offset = 1,
      side_padding = 1,
    })

    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      window = {
        completion = bordered_completion,
        documentation = bordered_documentation,
      },
      sources = {
        { name = "path" },
        { name = "cmdline" },
        -- Provides docs for `:set ...` options (boolean/type/default/description).
        { name = "nvim_options" },
      },
    })

    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      window = {
        completion = bordered_completion,
        documentation = bordered_documentation,
      },
      sources = {
        { name = "buffer" },
      },
    })

    -- Theme-aware highlights for completion menu
    local function setup_cmp_highlights()
      local theme_switcher_ok, theme_switcher = pcall(require, "theme_switcher")
      local current_theme = theme_switcher_ok and theme_switcher.current_id() or "default"
      local is_neon = current_theme == "neon_commit"

      local hl = vim.api.nvim_set_hl
      if is_neon then
        -- Neon theme: transparent with vibrant highlights
        hl(0, "CmpNormal",             { bg = "NONE", fg = "#ffffff" })
        hl(0, "CmpBorder",             { bg = "NONE", fg = "NONE" })
        hl(0, "CmpSelection",          { bg = "#1a1a2e", fg = "#ffffff" })
        hl(0, "CmpItemAbbrMatch",      { fg = "#ff2d95", bold = true })
        hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#ff2d95", bold = true })
        hl(0, "CmpItemAbbr",           { fg = "#ffffff" })
        hl(0, "CmpItemAbbrDeprecated", { fg = "#808080", strikethrough = true })
        hl(0, "CmpItemKindFunction",   { fg = "#ff2d95" })
        hl(0, "CmpItemKindMethod",     { fg = "#ff2d95" })
        hl(0, "CmpItemKindVariable",   { fg = "#00d7ff" })
        hl(0, "CmpItemKindKeyword",    { fg = "#CFFF04" })
        hl(0, "CmpItemKindClass",      { fg = "#9d7cff" })
        hl(0, "CmpItemKindInterface",  { fg = "#9d7cff" })
        hl(0, "CmpItemKindText",       { fg = "#ffffff" })
        hl(0, "CmpItemKindProperty",   { fg = "#00d7ff" })
        hl(0, "CmpItemKindField",      { fg = "#00d7ff" })
        hl(0, "CmpItemKindConstant",   { fg = "#ff9e1b" })
        hl(0, "CmpItemKindSnippet",    { fg = "#b7ff3a" })
        hl(0, "CmpItemKindModule",     { fg = "#d6afff" })
        hl(0, "CmpItemKindStruct",     { fg = "#9d7cff" })
        hl(0, "CmpItemKindEnum",       { fg = "#9d7cff" })
        hl(0, "CmpItemKindFile",       { fg = "#1e90ff" })
        hl(0, "CmpItemKindFolder",     { fg = "#1e90ff" })
        hl(0, "CmpItemMenu",           { fg = "#808080", italic = true })
        hl(0, "CmpDocNormal",          { bg = "NONE", fg = "#ffffff" })
        hl(0, "CmpDocBorder",          { bg = "NONE", fg = "NONE" })
        hl(0, "CmpDocHeader",          { fg = "#00d7ff", bold = true })
        hl(0, "markdownUrl",           { fg = "#9d7cff", underline = true })
        hl(0, "markdownLinkText",      { fg = "#9d7cff" })
        hl(0, "NoiceCmdlinePopupText",      { fg = "#00d7ff" })
        hl(0, "NoiceCmdlinePopupBorder",    { fg = "#ff2d95" })
        hl(0, "NoiceCmdlinePopupPrompt",    { fg = "#ff2d95" })
        hl(0, "NoiceCmdlinePopupSelection", { fg = "#000000", bg = "#ff2d95", bold = true })
      else
        -- Other themes: solid backgrounds with theme-aware colors
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        local is_dark = vim.o.background == "dark"
        
        local bg = normal.bg and string.format("#%06x", normal.bg) or (is_dark and "#1e1e2e" or "#f5f5f5")
        local fg = normal.fg and string.format("#%06x", normal.fg) or (is_dark and "#c8c8d0" or "#1a1a1a")
        local sel_bg = is_dark and "#2a2a40" or "#e6e6ef"
        local border = is_dark and "#3a3a50" or "#c0c0c8"
        local match = is_dark and "#7aa2f7" or "#2563eb"
        local menu = is_dark and "#9ece6a" or "#16a34a"
        
        vim.api.nvim_set_hl(0, "CmpNormal", { bg = bg, fg = fg })
        -- Borderless look: match bg
        vim.api.nvim_set_hl(0, "CmpBorder", { bg = bg, fg = bg })
        vim.api.nvim_set_hl(0, "CmpSelection", { bg = sel_bg, fg = fg, bold = false })
        vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = match, bold = true })
        vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = match, bold = true })
        vim.api.nvim_set_hl(0, "CmpItemAbbr", { fg = fg })
        -- Kind label should be muted (not loud)
        vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = border, italic = true })
        vim.api.nvim_set_hl(0, "CmpDocNormal", { bg = bg, fg = fg })
        vim.api.nvim_set_hl(0, "CmpDocBorder", { bg = bg, fg = bg })
        
        -- Kind highlights
        vim.api.nvim_set_hl(0, "CmpItemKindFunction", { fg = match })
        vim.api.nvim_set_hl(0, "CmpItemKindMethod", { fg = match })
        vim.api.nvim_set_hl(0, "CmpItemKindVariable", { fg = fg })
        vim.api.nvim_set_hl(0, "CmpItemKindKeyword", { fg = menu })

        -- Markdown/doc accents
        vim.api.nvim_set_hl(0, "markdownUrl", { fg = match, underline = true })
        vim.api.nvim_set_hl(0, "markdownLinkText", { fg = match })
      end
    end

    setup_cmp_highlights()

    -- Re-apply highlights when theme changes
    local cmp_hl_group = vim.api.nvim_create_augroup("CmpHighlights", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = cmp_hl_group,
      callback = setup_cmp_highlights,
    })
  end,
}
