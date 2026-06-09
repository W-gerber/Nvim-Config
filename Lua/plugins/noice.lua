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
        border = { style = "rounded", padding = { 0, 1 } },
        win_options = {
          winhighlight = "Normal:NoiceCmdlinePopup,FloatBorder:NoiceCmdlinePopupBorder,Search:None",
        },
      },
      popup = {
        border = { style = "rounded", padding = { 0, 1 } },
        win_options = {
          winhighlight = "Normal:NoicePopup,FloatBorder:NoicePopupBorder,Search:None",
        },
      },
      popupmenu = {
        border = { style = "rounded", padding = { 0, 1 } },
        win_options = {
          winhighlight = "Normal:NoicePopupmenu,FloatBorder:NoicePopupmenuBorder,CursorLine:NoicePopupmenuSelected,Search:None",
        },
      },
      confirm = {
        border = { style = "rounded", padding = { 0, 1 } },
        win_options = {
          winhighlight = "Normal:NoiceConfirm,FloatBorder:NoiceConfirmBorder,Search:None",
        },
      },
    },
  },
  config = function(_, opts)
    local ok, noice = pcall(require, "noice")
    if not ok then
      return
    end

    local ui = require("core.ui")

    local function apply_noice_highlights()
      local palette = ui.float_palette()
      local hl = vim.api.nvim_set_hl

      hl(0, "NoiceCmdlinePopup", { bg = palette.bg, fg = palette.fg })
      hl(0, "NoiceCmdlinePopupBorder", { bg = palette.bg, fg = palette.border })
      hl(0, "NoiceCmdlinePopupTitle", { bg = palette.bg, fg = palette.accent, bold = true })
      hl(0, "NoiceCmdlinePopupPrompt", { fg = palette.accent, bg = palette.bg, bold = true })
      hl(0, "NoicePopup", { bg = palette.bg, fg = palette.fg })
      hl(0, "NoicePopupBorder", { bg = palette.bg, fg = palette.border })
      hl(0, "NoicePopupTitle", { bg = palette.bg, fg = palette.accent, bold = true })
      hl(0, "NoicePopupmenu", { bg = palette.bg, fg = palette.fg })
      hl(0, "NoicePopupmenuBorder", { bg = palette.bg, fg = palette.border })
      hl(0, "NoicePopupmenuSelected", { bg = palette.selection_bg, fg = palette.selection_fg, bold = true })
      hl(0, "NoiceConfirm", { bg = palette.bg, fg = palette.fg })
      hl(0, "NoiceConfirmBorder", { bg = palette.bg, fg = palette.border })
      hl(0, "NoiceMini", { fg = palette.fg, bg = "NONE" })
    end

    apply_noice_highlights()
    local noice_group = ui.create_augroup("NoiceThemeHighlights")
    ui.on_theme_change(noice_group, apply_noice_highlights)

    noice.setup(opts)
  end,
}
