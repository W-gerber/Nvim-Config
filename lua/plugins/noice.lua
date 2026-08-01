-- noice.nvim: the cmdline, its completion menu and the message popups, styled
-- as the same frosted glass panels as which-key.
--
-- The recipe is identical everywhere: a pane from `ui.pane_bg()` — nothing at
-- all while the editor is transparent, so the terminal's own acrylic shows
-- through, and a neutral frosted surface otherwise — and a rim that is lit
-- along the top and shadowed along the bottom.

local ui = require("core.ui")

--- The shared beveled rim (see `core.ui.glass_border`), in the shape nui wants:
--- the pairs go under `style`, and the padding keeps text off the rim.
---@param prefix string highlight prefix, e.g. "NoiceCmdlinePopup"
---@return table
local function glass_border(prefix)
  return { style = ui.glass_border(prefix), padding = { 0, 1 } }
end

-- Each cmdline mode gets its own glyph and title, and noice derives a highlight
-- group per mode from the `kind` — see the badge colors below. The popup then
-- announces what you are typing into: a `:command`, a `/search`, a `:lua`
-- chunk, before you have read a character of it.
local CMDLINE_FORMATS = {
  cmdline = {
    pattern = "^:",
    icon = "\u{e6ae}", -- nf-custom-neovim
    lang = "vim",
    title = " Command ",
  },
  search_down = {
    kind = "search",
    pattern = "^/",
    icon = "\u{f0349}", -- nf-md-magnify
    lang = "regex",
    title = " Search \u{f0045} ", -- nf-md-arrow_down
  },
  search_up = {
    kind = "search",
    pattern = "^%?",
    icon = "\u{f0349}",
    lang = "regex",
    title = " Search \u{f0046} ", -- nf-md-arrow_up
  },
  filter = {
    pattern = "^:%s*!",
    icon = "\u{f120}", -- nf-fa-terminal
    lang = "bash",
    title = " Shell ",
  },
  lua = {
    pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" },
    icon = "\u{e620}", -- nf-seti-lua
    lang = "lua",
    title = " Lua ",
  },
  help = {
    pattern = "^:%s*he?l?p?%s+",
    icon = "\u{f059}", -- nf-fa-question_circle
    title = " Help ",
  },
  calculator = {
    pattern = "^=",
    icon = "\u{f1ec}", -- nf-fa-calculator
    lang = "vimnormal",
    title = " Calculate ",
  },
  input = {
    view = "cmdline_input",
    icon = "\u{f040}", -- nf-fa-pencil
    title = " Input ",
  },
}

-- Badge color per cmdline mode, as palette keys. The table keys are noice's
-- capitalized `kind`s, which is how it names the groups it generates from the
-- formats above.
--
-- `blue` is missing on purpose: on themes that do not publish their own palette
-- the accent *is* the blue, so a blue badge would be indistinguishable from the
-- plain `:command` one.
local CMDLINE_KINDS = {
  Cmdline = "accent",
  Search = "yellow",
  Filter = "green",
  Lua = "purple",
  Help = "cyan",
  Calculator = "orange",
  Input = "pink",
}

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    cmdline = { format = CMDLINE_FORMATS },
    messages = { enabled = true, view = "mini" },
    routes = { { filter = { event = "msg_showmode" }, view = "mini" } },
    presets = {
      bottom_search = true,
      command_palette = false,
      long_message_to_split = true,
      lsp_doc_border = true,
    },
    views = {
      cmdline_popup = {
        -- Centred: nui reads a percentage as a share of the *free* space, so
        -- 50/50 splits the margin evenly on every axis.
        position = { row = "50%", col = "50%" },
        size = { min_width = 64, width = "auto", height = "auto" },
        border = glass_border("NoiceCmdlinePopup"),
        win_options = {
          -- No blending anywhere in this file: it composites the float against
          -- the editor cells below, which is what stops a transparent terminal
          -- from showing through. See `ui.pane_bg()`.
          winblend = 0,
          winhighlight = {
            Normal = "NoiceCmdlinePopup",
            IncSearch = "",
            CurSearch = "",
            Search = "",
          },
        },
      },
      popupmenu = {
        border = glass_border("NoicePopupmenu"),
        win_options = {
          winblend = 0,
          winhighlight = {
            Normal = "NoicePopupmenu",
            CursorLine = "NoicePopupmenuSelected",
            PmenuMatch = "NoicePopupmenuMatch",
            Search = "",
          },
        },
      },
      popup = {
        border = glass_border("NoicePopup"),
        win_options = {
          winblend = 0,
          winhighlight = { Normal = "NoicePopup", Search = "" },
        },
      },
      confirm = {
        border = glass_border("NoiceConfirm"),
        win_options = {
          winblend = 0,
          winhighlight = { Normal = "NoiceConfirm", Search = "" },
        },
      },
      -- Message toasts. They keep a faint pane when the editor is opaque, which
      -- is what stops a message landing on top of code from reading as garbled
      -- text; transparent, they are just text over the terminal.
      mini = {
        win_options = {
          winblend = 0,
          winhighlight = { Normal = "NoiceMini", IncSearch = "", CurSearch = "", Search = "" },
        },
      },
    },
  },
  config = function(_, opts)
    local ok, noice = pcall(require, "noice")
    if not ok then
      return
    end

    local function apply_noice_highlights()
      local p = ui.palette()
      local hl = vim.api.nvim_set_hl

      -- `NONE` while the glass preference is on, so a transparent terminal
      -- keeps its own blur behind these panels; a frosted surface otherwise.
      local pane = ui.pane_bg(0.1)
      local toast = ui.pane_bg(0.06)

      -- The selected row keeps a background either way: it is one line, and
      -- without it there is nothing marking the selection but the text color.
      local selected = ui.frost(0.18)

      -- Rim tones mix against the theme's backdrop, not the pane, which may
      -- have no color to mix with.
      local rim = ui.blend(p.accent, p.bg, 0.5)
      local rim_top = ui.blend(p.accent, p.fg, 0.7)
      local rim_bottom = ui.blend(p.muted, p.bg, 0.6)

      --- Pane and beveled rim for one view.
      ---@param prefix string
      local function surface(prefix)
        hl(0, prefix, { fg = p.fg, bg = pane })
        hl(0, prefix .. "Border", { fg = rim, bg = pane })
        hl(0, prefix .. "BorderTop", { fg = rim_top, bg = pane })
        hl(0, prefix .. "BorderBottom", { fg = rim_bottom, bg = pane })
        hl(0, prefix .. "Title", { fg = ui.contrast(p.accent), bg = p.accent, bold = true })
      end

      surface("NoiceCmdlinePopup")
      surface("NoicePopup")
      surface("NoicePopupmenu")
      surface("NoiceConfirm")

      -- One badge per cmdline mode. noice generates
      -- `NoiceCmdlinePopupTitle<Kind>` and `NoiceCmdlineIcon<Kind>` from the
      -- formats above and paints the border title with the first, which is what
      -- turns the popup's top edge into a mode chip.
      for kind, name in pairs(CMDLINE_KINDS) do
        local color = p[name]
        hl(0, "NoiceCmdlinePopupTitle" .. kind, { fg = ui.contrast(color), bg = color, bold = true })
        hl(0, "NoiceCmdlineIcon" .. kind, { fg = color, bg = pane })
        -- The generated border groups only reach the padding cells (the rim
        -- characters carry their own), but leaving them unset would punch
        -- differently-shaded gaps into the pane.
        hl(0, "NoiceCmdlinePopupBorder" .. kind, { fg = ui.blend(color, p.bg, 0.5), bg = pane })
      end

      hl(0, "NoiceCmdlineIcon", { fg = p.accent, bg = pane })
      hl(0, "NoiceCmdlinePopupPrompt", { fg = p.accent, bg = pane, bold = true })
      hl(0, "NoiceCmdlinePrompt", { fg = p.accent, bold = true })

      -- The classic bottom cmdline (search, thanks to `bottom_search`) stays on
      -- the editor background — it is a line, not a panel.
      hl(0, "NoiceCmdline", { fg = p.fg, bg = "NONE" })

      -- Completion menu.
      hl(0, "NoicePopupmenuSelected", { fg = p.accent, bg = selected, bold = true })
      hl(0, "NoicePopupmenuMatch", { fg = p.accent, bold = true })
      hl(0, "NoiceScrollbar", { bg = selected })
      hl(0, "NoiceScrollbarThumb", { bg = ui.blend(p.accent, pane, 0.6) })

      -- Toasts, virtual text and progress.
      hl(0, "NoiceMini", { fg = p.muted, bg = toast })
      hl(0, "NoiceVirtualText", { fg = p.muted, bg = "NONE" })
      hl(0, "NoiceFormatProgressDone", { fg = ui.contrast(p.green), bg = p.green })
      hl(0, "NoiceFormatProgressTodo", { fg = p.muted, bg = selected })
      hl(0, "NoiceLspProgressTitle", { fg = p.fg })
      hl(0, "NoiceLspProgressClient", { fg = p.accent, bold = true })
      hl(0, "NoiceLspProgressSpinner", { fg = p.cyan })

      -- Split views (long messages, `:Noice`) follow the editor, not the glass.
      hl(0, "NoiceSplit", { fg = p.fg, bg = "NONE" })
      hl(0, "NoiceSplitBorder", { fg = p.border, bg = "NONE" })
    end

    apply_noice_highlights()
    local noice_group = ui.create_augroup("NoiceThemeHighlights")
    ui.on_theme_change(noice_group, apply_noice_highlights)

    noice.setup(opts)
  end,
}
