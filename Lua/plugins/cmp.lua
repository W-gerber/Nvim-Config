return {
  "hrsh7th/nvim-cmp",
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
    local cmp_types_ok, cmp_types = pcall(require, "cmp.types")

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

          -- Optional: add Lua docs link for builtins when LSP doesn't provide one.
          -- We keep this minimal and non-intrusive: it will appear in the docs window via LSP docs,
          -- but if LSP docs are empty, we can still provide a hint.
          if cmp_types_ok and entry and entry.source and entry.source.name == "nvim_lsp" then
            -- no-op; LSP handles documentation
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
        ghost_text = true,
      },
    })

    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
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
      sources = {
        { name = "buffer" },
      },
    })

    -- Theme-aware highlights for completion menu
    local function setup_cmp_highlights()
      local theme_switcher_ok, theme_switcher = pcall(require, "theme_switcher")
      local current_theme = theme_switcher_ok and theme_switcher.current_id() or "default"
      local is_neon = current_theme == "neon_commit"

      if is_neon then
        -- Neon theme: transparent with vibrant highlights
        vim.cmd [[
          " Completion window (rounded but borderless-looking)
          hi CmpNormal              guibg=NONE guifg=#ffffff
          hi CmpBorder              guibg=NONE guifg=NONE
          hi CmpSelection           guibg=#1a1a2e guifg=#ffffff gui=NONE

          " Item components
          hi CmpItemAbbrMatch       guifg=#ff2d95 guibg=NONE gui=bold
          hi CmpItemAbbrMatchFuzzy  guifg=#ff2d95 guibg=NONE gui=bold
          hi CmpItemAbbr            guifg=#ffffff guibg=NONE
          hi CmpItemAbbrDeprecated  guifg=#808080 guibg=NONE gui=strikethrough

          " Kind/Type icons (left side)
          hi CmpItemKindFunction    guifg=#ff2d95 guibg=NONE
          hi CmpItemKindMethod      guifg=#ff2d95 guibg=NONE
          hi CmpItemKindVariable    guifg=#00d7ff guibg=NONE
          hi CmpItemKindKeyword     guifg=#CFFF04 guibg=NONE
          hi CmpItemKindClass       guifg=#9d7cff guibg=NONE
          hi CmpItemKindInterface   guifg=#9d7cff guibg=NONE
          hi CmpItemKindText        guifg=#ffffff guibg=NONE
          hi CmpItemKindProperty    guifg=#00d7ff guibg=NONE
          hi CmpItemKindField       guifg=#00d7ff guibg=NONE
          hi CmpItemKindConstant    guifg=#ff9e1b guibg=NONE
          hi CmpItemKindSnippet     guifg=#b7ff3a guibg=NONE
          hi CmpItemKindModule      guifg=#d6afff guibg=NONE
          hi CmpItemKindStruct      guifg=#9d7cff guibg=NONE
          hi CmpItemKindEnum        guifg=#9d7cff guibg=NONE
          hi CmpItemKindFile        guifg=#1e90ff guibg=NONE
          hi CmpItemKindFolder      guifg=#1e90ff guibg=NONE

          " Kind label on the right (muted)
          hi CmpItemMenu            guifg=#808080 guibg=NONE gui=italic

          " Documentation window (rounded but borderless-looking)
          hi CmpDocNormal           guibg=NONE guifg=#ffffff
          hi CmpDocBorder           guibg=NONE guifg=NONE

          " Markdown/doc accents
          hi CmpDocHeader           guifg=#00d7ff guibg=NONE gui=bold
          hi markdownUrl            guifg=#9d7cff guibg=NONE gui=underline
          hi markdownLinkText       guifg=#9d7cff guibg=NONE

          " Noice cmdline popup
          hi NoiceCmdlinePopupText       guifg=#00d7ff guibg=NONE
          hi NoiceCmdlinePopupBorder     guifg=#ff2d95 guibg=NONE
          hi NoiceCmdlinePopupPrompt     guifg=#ff2d95 guibg=NONE
          hi NoiceCmdlinePopupSelection  guifg=#000000 guibg=#ff2d95 gui=bold
        ]]
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
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = setup_cmp_highlights,
    })
  end,
}
