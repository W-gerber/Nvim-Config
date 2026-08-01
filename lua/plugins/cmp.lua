return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-nvim-lsp",
    "onsails/lspkind.nvim", -- Icons for completion items
    {
      "L3MON4D3/LuaSnip", -- Snippet engine
      version = "v2.*",
      -- Without a snippet collection the `luasnip` source below had nothing to
      -- offer; friendly-snippets supplies the VS Code style snippet library.
      dependencies = { "rafamadriz/friendly-snippets" },
    },
    "saadparwaiz1/cmp_luasnip", -- Snippet completion source
  },
  config = function()
    local ok_cmp, cmp = pcall(require, "cmp")
    if not ok_cmp then
      return
    end

    local ui = require("core.ui")

    -- VS Code–style inline documentation:
    -- nvim-cmp can show a bordered documentation window for the *currently selected*
    -- completion item. For LSP items, docs come from the LSP. For Neovim `:set` options,
    -- we register a small custom source that attaches type/default/description.
    pcall(function()
      local src = require("cmp_sources.nvim_options").new()
      cmp.register_source("nvim_options", src)
    end)

    local ok_lspkind, lspkind = pcall(require, "lspkind")
    local ok_luasnip, luasnip = pcall(require, "luasnip")

    -- Setup LuaSnip if available
    if ok_luasnip then
      pcall(function() require("luasnip.loaders.from_vscode").lazy_load() end)
    end

    -- The menu and its docs pane, defined once and reused by the buffer
    -- completion and both cmdline completions below — they were previously
    -- spelled out twice, identically, and only one copy ever got edited.
    local windows = {
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
    }

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

      window = windows,

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
        { name = "luasnip", priority = 750 },
        { name = "path", priority = 500 },
      }, {
        { name = "buffer", priority = 250, keyword_length = 3 },
      }),

      experimental = {
        ghost_text = false,
      },
    })

    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      window = windows,
      sources = {
        { name = "path" },
        { name = "cmdline" },
        -- Provides docs for `:set ...` options (boolean/type/default/description).
        { name = "nvim_options" },
      },
    })

    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      window = windows,
      sources = {
        { name = "buffer" },
      },
    })

    -- Completion menu highlights, derived from the active theme instead of the
    -- two hard-coded palettes this used to carry (one neon, one "everything
    -- else"), which drifted apart as themes were added.
    local function setup_cmp_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      -- Nothing at all while the editor is transparent, so the terminal's own
      -- blur shows through the menu; a neutral frost otherwise (never the
      -- accent-tinted panel, which reads as colored film at this size).
      local menu_bg = ui.pane_bg(0.1)
      local menu_fg = ui.contrast(ui.frost(0.1), p.bg, p.fg)

      -- The border used to be painted in the menu's own color for a borderless
      -- look. That only works while the menu has a color: with a transparent
      -- pane it would leave the rounded characters in the default foreground,
      -- so they get a dim rim of their own instead.
      local rim = vim.g.ui_transparent and ui.blend(p.accent, p.bg, 0.45) or menu_bg

      hl(0, "CmpNormal", { bg = menu_bg, fg = menu_fg })
      hl(0, "CmpBorder", { bg = menu_bg, fg = rim })
      hl(0, "CmpSelection", { bg = p.selection_bg, fg = p.selection_fg, bold = true })
      hl(0, "CmpDocNormal", { bg = menu_bg, fg = menu_fg })
      hl(0, "CmpDocBorder", { bg = menu_bg, fg = rim })
      hl(0, "CmpDocHeader", { fg = p.accent, bold = true })

      hl(0, "CmpItemAbbr", { fg = menu_fg })
      hl(0, "CmpItemAbbrMatch", { fg = p.accent, bold = true })
      hl(0, "CmpItemAbbrMatchFuzzy", { fg = p.accent, bold = true })
      hl(0, "CmpItemAbbrDeprecated", { fg = p.muted, strikethrough = true })
      hl(0, "CmpItemMenu", { fg = p.muted, italic = true })

      -- Completion kinds, grouped by what they are rather than one-off colors.
      --
      -- A list of pairs, not a table keyed by color. Palette entries fall back
      -- to one another when a theme doesn't define the group they are derived
      -- from — `pink` to `purple`, `orange` to `yellow`, `cyan` to `blue` — and
      -- on any theme where two of them land on the same hex, a color-keyed
      -- table silently collapses the two rows into one. The earlier list is
      -- discarded, and four to seven kinds lose their color with nothing to
      -- show for it. Most themes without their own `ui_palette` hit this.
      local kind_groups = {
        { p.pink, { "Function", "Method", "Constructor", "Event" } },
        { p.cyan, { "Variable", "Property", "Field", "Reference" } },
        { p.purple, { "Class", "Interface", "Struct", "Enum", "EnumMember", "Module", "TypeParameter" } },
        { p.yellow, { "Keyword", "Operator", "Unit", "Value" } },
        { p.orange, { "Constant", "Color" } },
        { p.green, { "Snippet", "Text" } },
        { p.blue, { "File", "Folder" } },
      }

      for _, group in ipairs(kind_groups) do
        local color, kinds = group[1], group[2]
        for _, kind in ipairs(kinds) do
          hl(0, "CmpItemKind" .. kind, { fg = color })
        end
      end

      hl(0, "markdownUrl", { fg = p.accent, underline = true })
      hl(0, "markdownLinkText", { fg = p.accent })
    end

    setup_cmp_highlights()
    ui.on_theme_change(ui.create_augroup("CmpHighlights"), setup_cmp_highlights)
  end,
}
